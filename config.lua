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
    -- Server-wide font overrides, editable live in kora_lib's /config. 'theme'
    -- follows theme.json's "fonts"; 'default' is the built-in stack; any other
    -- value is an id from fonts/catalog.json. A non-empty custom family list
    -- overrides the choice for its slot. Precedence: these > theme.json > default.
    fonts = {
        heading = 'theme',
        body = 'theme',
        mono = 'theme',
        custom = { heading = '', body = '', mono = '' },
    },
}

local FONT_FIELDS = {
    { slot = 'body', label = 'Body font', default = 'Built-in (Inter / system)',
        description = 'Font for ordinary text in every Kora UI.' },
    { slot = 'heading', label = 'Heading font', default = 'Same as body font',
        description = 'Font for titles and headings in every Kora UI.' },
    { slot = 'mono', label = 'Monospace font', default = 'Built-in (system monospace)',
        description = 'Font for codes, numbers and other fixed-width text in every Kora UI.' },
}

-- Builds the /config descriptors for QBThemeConfig.fonts. The dropdown lists
-- the bundled fonts from fonts/catalog.json; the monospace slot lists only
-- monospace fonts. Changes apply live to every open UI.
local function fontDescriptors(bridge)
    local fonts = type(QBThemeConfig.fonts) == 'table' and QBThemeConfig.fonts or {}
    local custom = type(fonts.custom) == 'table' and fonts.custom or {}
    local catalog = type(KoraThemeFile) == 'table' and KoraThemeFile.catalog or {}
    local descriptors = { custom = {} }
    for _, field in ipairs(FONT_FIELDS) do
        local kind = KoraThemeFile.fontSlots[field.slot]
        local options = {
            { value = 'theme', label = 'Server default (theme.json)' },
            { value = 'default', label = field.default },
        }
        for _, font in ipairs(catalog) do
            if kind == 'sans' or font.kind == kind then options[#options + 1] = { value = font.id, label = font.label } end
        end
        local selected = fonts[field.slot]
        local valid = false
        for _, option in ipairs(options) do valid = valid or option.value == selected end
        descriptors[field.slot] = bridge.enum(valid and selected or 'theme', {
            label = field.label, options = options, live = true,
            description = field.description .. ' Server default follows theme.json; changes apply to open UIs immediately.',
        })
        descriptors.custom[field.slot] = bridge.string(type(custom[field.slot]) == 'string' and custom[field.slot] or '', {
            label = ('Custom %s family'):format(field.label:lower()),
            description = ('Optional CSS font-family list such as "Arial, sans-serif" that overrides the %s choice. The font must be installed on the player\'s PC or bundled in kora_theme/fonts. Only letters, digits, spaces, commas, quotes and hyphens are allowed; leave empty to use the dropdown.'):format(field.label:lower()),
            maxLength = 200, pattern = '^[%w ,\'"%-]*$', live = true, advanced = true,
        })
    end
    return descriptors
end

local function announceFonts()
    -- Each consumer's bridge.lua listens for this local event and forwards the
    -- resolved fonts to its own NUI frame.
    if type(TriggerEvent) == 'function' then TriggerEvent('qbtheme:fontsChanged') end
end

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
    for _, field in ipairs(FONT_FIELDS) do
        bridge.onChange('fonts.' .. field.slot, announceFonts)
        bridge.onChange('fonts.custom.' .. field.slot, announceFonts)
    end
    local values = {}
    for key, value in pairs(QBThemeConfig) do values[key] = value end
    values.fonts = fontDescriptors(bridge)
    QBThemeConfig = bridge.adopt(values)
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
