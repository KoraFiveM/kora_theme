-- Loads theme.json, the single source of truth for every kora_theme colour and
-- font choice, plus fonts/catalog.json, the list of bundled fonts. Runs first in
-- both the server and client VM; config.lua and shared.lua read the result from
-- KoraThemeFile instead of keeping their own palette or font list.
--
-- EMERGENCY is used only when theme.json is missing or invalid, and a warning
-- is printed whenever it is. Edit theme.json, never this table.
local EMERGENCY = {
    background = '#101010', surface = '#171717', surfacePopover = '#1B1B1B', surfaceRaised = '#242424',
    surfaceHover = '#2A2A2A', foreground = '#F5F5F5', mutedForeground = '#949494', border = '#343434',
    borderStrong = '#444444', control = '#666666', controlHover = '#7A7A7A', primary = '#A8FF00',
    success = '#22C55E', warning = '#F59E0B', danger = '#EF4444', info = '#D4D4D4', armour = '#3B9EFF',
}

-- Used only when fonts/catalog.json is missing or invalid. These are the
-- theme.css defaults; the catalog's "defaults" normally supplies them.
local EMERGENCY_FONTS = {
    sans = 'Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif',
    mono = '"SFMono-Regular", Consolas, "Liberation Mono", monospace',
}
local FONT_SLOTS = { heading = 'sans', body = 'sans', mono = 'mono' }

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
local themeData

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
        themeData = data
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

local fontDefaults = { sans = EMERGENCY_FONTS.sans, mono = EMERGENCY_FONTS.mono }
local catalog, catalogById = {}, {}
local rawCatalog = type(LoadResourceFile) == 'function' and LoadResourceFile(resource, 'fonts/catalog.json') or nil
local catalogOk, catalogData = false, nil
if type(rawCatalog) == 'string' and rawCatalog ~= '' and type(json) == 'table' and type(json.decode) == 'function' then
    catalogOk, catalogData = pcall(json.decode, rawCatalog)
end
if not catalogOk or type(catalogData) ~= 'table' or type(catalogData.fonts) ~= 'table' then
    warn('fonts/catalog.json is missing or invalid; only the default fonts are available.')
else
    if type(catalogData.defaults) == 'table' then
        for kind in pairs(fontDefaults) do
            if type(catalogData.defaults[kind]) == 'string' then fontDefaults[kind] = catalogData.defaults[kind] end
        end
    end
    for _, font in ipairs(catalogData.fonts) do
        if type(font) == 'table' and type(font.id) == 'string' and font.id:match('^[a-z0-9][a-z0-9-]*$') and font.id ~= 'default'
            and type(font.label) == 'string' and type(font.stack) == 'string' and fontDefaults[font.kind] and not catalogById[font.id] then
            local entry = { id = font.id, label = font.label, kind = font.kind, family = font.family, stack = font.stack }
            catalog[#catalog + 1] = entry
            catalogById[entry.id] = entry
        end
    end
end

-- A custom family list may only contain names: letters, digits, spaces,
-- commas, quotes and hyphens, with balanced quotes. This rejects ; { } ( ) < >
-- and so url(...), var(...) and anything else that could escape the value.
local function sanitiseFamily(value)
    if type(value) ~= 'string' then return nil end
    value = value:match('^%s*(.-)%s*$')
    if value == '' or #value > 200 or not value:match('^[%w ,\'"%-]+$') or not value:match('%a') then return nil end
    if select(2, value:gsub('"', '')) % 2 ~= 0 or select(2, value:gsub("'", '')) % 2 ~= 0 then return nil end
    return value
end

---Resolves a font value ("default", a catalog id, or a custom family list) for
---a kind ('sans' or 'mono'). Returns { id, label, stack } or nil when invalid.
---"default" has no stack of its own; callers apply the slot default.
local function resolveFont(value, kind)
    if value == 'default' then return { id = 'default', label = 'Default' } end
    if type(value) ~= 'string' then return nil end
    local font = catalogById[value:lower()]
    if font then return { id = font.id, label = font.label, stack = font.stack } end
    local family = sanitiseFamily(value)
    if not family then return nil end
    return { id = 'custom', label = family, stack = ('%s, %s'):format(family, fontDefaults[kind] or fontDefaults.sans) }
end

local fonts = { heading = 'default', body = 'default', mono = 'default' }
local configuredFonts = themeData and themeData.fonts
if configuredFonts ~= nil and type(configuredFonts) ~= 'table' then
    warn('theme.json "fonts" must be an object; using the default fonts.')
elseif configuredFonts then
    for slot, kind in pairs(FONT_SLOTS) do
        local value = configuredFonts[slot]
        if value ~= nil then
            if resolveFont(value, kind) then
                fonts[slot] = value
            else
                warn(('theme.json font %q must be "default", a fonts/catalog.json id or a plain font-family list; using the default.'):format(slot))
            end
        end
    end
end

KoraThemeFile = {
    source = source, -- 'theme.json' or 'emergency'
    colours = colours,
    name = name, -- label for the primary colour, shown as the first picker preset
    presets = presets, -- extra picker presets from theme.json
    fonts = fonts, -- validated theme.json font values per slot (heading, body, mono)
    fontSlots = FONT_SLOTS, -- slot -> kind ('sans' or 'mono')
    fontDefaults = fontDefaults, -- kind -> default stack, matching theme.css
    catalog = catalog, -- bundled fonts from fonts/catalog.json, in order
    resolveFont = resolveFont,
}
