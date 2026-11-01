-- Colours are NOT configured here: edit theme.json, the single source of truth
-- (loaded by theme_loader.lua). This file only holds behaviour options.
QBThemeConfig = {
    -- Players can choose a personal primary colour with /theme. The choice is
    -- saved in client KVP storage and never leaves their machine. Set enabled
    -- to false to keep the server-wide colour from theme.json for everyone.
    -- The picker presets and the name of the default colour live in theme.json.
    playerTheme = {
        enabled = true,
        command = 'theme',
        kvpKey = 'qbtheme:playerTheme',
    },
}

-- kora_lib depends on kora_theme, so this resource cannot declare kora_lib as a normal
-- manifest dependency. Once kora_lib finishes starting, load the same
-- consumer-local bridge used by every other resource and register the theme
-- table without creating a startup cycle.
local function registerConfiguration()
    local source = LoadResourceFile and LoadResourceFile('kora_lib', 'modules/config/consumer.lua')
    if type(source) ~= 'string' or source == '' then return false end

    local factory, loadError = load(source, '@@kora_lib/modules/config/consumer.lua', 't', _ENV)
    if not factory then
        print(('[qbtheme] Could not load the kora_lib configuration bridge: %s'):format(loadError))
        return false
    end

    local bridge = factory()({
        config_register = function(_, definition)
            return exports.kora_lib:config_register(definition)
        end,
    })
    QBThemeConfig = bridge.adopt(QBThemeConfig)
    return true
end

local function deferRegistration()
    if type(SetTimeout) == 'function' then
        SetTimeout(0, registerConfiguration)
    else
        registerConfiguration()
    end
end

if type(GetResourceState) == 'function' and GetResourceState('kora_lib') == 'started' then
    deferRegistration()
elseif type(AddEventHandler) == 'function' then
    AddEventHandler('onResourceStart', function(resource)
        if resource == 'kora_lib' then deferRegistration() end
    end)
end
