-- The palette is kept in theme.json so the loadscreen can read it before a
-- client-side NUI callback exists. This Lua shim keeps the public QBThemeConfig
-- table available to runtime exports without duplicating those values.
local fallback = {
    background = '#101010',
    surface = '#171717',
    surfacePopover = '#1B1B1B',
    surfaceRaised = '#242424',
    surfaceHover = '#2A2A2A',
    foreground = '#F5F5F5',
    mutedForeground = '#949494',
    border = '#343434',
    borderStrong = '#444444',
    control = '#666666',
    controlHover = '#7A7A7A',
    primary = '#95FF00',
    success = '#22C55E',
    warning = '#F59E0B',
    danger = '#EF4444',
    info = '#D4D4D4',
    armour = '#3B9EFF',
}

local colours = {}
for key, value in pairs(fallback) do colours[key] = value end

if type(LoadResourceFile) == 'function' then
    local resource = type(GetCurrentResourceName) == 'function' and GetCurrentResourceName() or 'kora_theme'
    local ok, raw = pcall(LoadResourceFile, resource, 'theme.json')
    if ok and type(raw) == 'string' then
        -- theme.json is deliberately a flat colour map. Parsing the known
        -- #RRGGBB entries avoids relying on a JSON global during early client
        -- startup; shared.lua still validates every value before use.
        for key, value in raw:gmatch('"([%a]+)"%s*:%s*"(#%x%x%x%x%x%x)"') do
            colours[key] = value
        end
    end
end

QBThemeConfig = {
    colors = colours,

    -- Players can choose a personal primary colour with /theme. The choice is
    -- saved in client KVP storage and never leaves their machine. Set enabled
    -- to false to keep the server-wide colour from theme.json for everyone.
    playerTheme = {
        enabled = true,
        command = 'theme',
        kvpKey = 'qbtheme:playerTheme',
        presets = {
            { label = 'Crimson', colour = '#DC143C' },
            { label = 'Orange', colour = '#F97316' },
            { label = 'Amber', colour = '#F59E0B' },
            { label = 'Lime', colour = '#95FF00' },
            { label = 'Emerald', colour = '#22C55E' },
            { label = 'Cyan', colour = '#06B6D4' },
            { label = 'Blue', colour = '#3B82F6' },
            { label = 'Violet', colour = '#7C3AED' },
            { label = 'Pink', colour = '#EC4899' },
        },
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
