-- Loads theme.json, the single source of truth for every kora_theme colour.
-- Runs first in both the server and client VM; config.lua and shared.lua read
-- the result from KoraThemeFile instead of keeping their own palette.
--
-- EMERGENCY is used only when theme.json is missing or invalid, and a warning
-- is printed whenever it is. Edit theme.json, never this table.
local EMERGENCY = {
    background = '#101010', surface = '#171717', surfacePopover = '#1B1B1B', surfaceRaised = '#242424',
    surfaceHover = '#2A2A2A', foreground = '#F5F5F5', mutedForeground = '#949494', border = '#343434',
    borderStrong = '#444444', control = '#666666', controlHover = '#7A7A7A', primary = '#95FF00',
    success = '#22C55E', warning = '#F59E0B', danger = '#EF4444', info = '#D4D4D4', armour = '#3B9EFF',
}

local function warn(message)
    print(('^3[kora_theme] %s^7'):format(message))
end

local function validHex(value)
    return type(value) == 'string' and value:match('^#%x%x%x%x%x%x$') ~= nil
end

local colours = {}
for key, value in pairs(EMERGENCY) do colours[key] = value end
local presets, name = {}, nil
local source = 'emergency'

local resource = type(GetCurrentResourceName) == 'function' and GetCurrentResourceName() or 'kora_theme'
local raw = type(LoadResourceFile) == 'function' and LoadResourceFile(resource, 'theme.json') or nil

if type(raw) ~= 'string' or raw == '' then
    warn('theme.json is missing or unreadable; using the built-in emergency colours.')
elseif type(json) ~= 'table' or type(json.decode) ~= 'function' then
    warn('The json library is unavailable; using the built-in emergency colours.')
else
    local ok, data = pcall(json.decode, raw)
    if not ok or type(data) ~= 'table' or type(data.colors) ~= 'table' then
        warn('theme.json is not valid JSON with a "colors" object; using the built-in emergency colours.')
    else
        source = 'theme.json'
        for key in pairs(EMERGENCY) do
            local value = data.colors[key]
            if validHex(value) then
                colours[key] = value:upper()
            else
                warn(('theme.json colour %q must be #RRGGBB; using the emergency default %s.'):format(key, EMERGENCY[key]))
            end
        end
        if type(data.name) == 'string' and data.name ~= '' then name = data.name end
        if type(data.presets) == 'table' then
            for _, preset in ipairs(data.presets) do
                if type(preset) == 'table' and type(preset.label) == 'string' and validHex(preset.colour) then
                    presets[#presets + 1] = { label = preset.label, colour = preset.colour:upper() }
                end
            end
        end
    end
end

KoraThemeFile = {
    source = source, -- 'theme.json' or 'emergency'
    colours = colours,
    name = name, -- label for the primary colour, shown as the first picker preset
    presets = presets, -- extra picker presets from theme.json
}
