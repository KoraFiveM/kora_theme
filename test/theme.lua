local root = debug.getinfo(1, 'S').source:sub(2):match('(.*/)') .. '../'
local registered = {}

_G.exports = setmetatable({}, {
    __call = function(_, name, fn) registered[name] = fn end,
})

_G.GetCurrentResourceName = function() return 'kora_theme' end
_G.LoadResourceFile = function(_, path)
    local file = assert(io.open(root .. path, 'r'))
    local content = file:read('*a')
    file:close()
    return content
end
dofile(root .. 'test/json.lua')
dofile(root .. 'theme_loader.lua')
dofile(root .. 'config.lua')
dofile(root .. 'shared.lua')

local function equal(actual, expected, message)
    if actual ~= expected then error(('%s: expected %s, got %s'):format(message, tostring(expected), tostring(actual)), 2) end
end

local tokens = registered.getTokens()
local configuredPrimary = json.decode(assert(io.open(root .. 'theme.json', 'r')):read('*a')).colors.primary
equal(KoraThemeFile.source, 'theme.json', 'palette comes from theme.json')
equal(registered.getPrimaryColor(), configuredPrimary, 'configured primary')
assert(type(tokens.primary) == 'string' and tokens.primary:match('%%') ~= nil, 'primary HSL')
equal(tokens.background, '0 0% 6.3%', 'background HSL')
assert(tokens['brand-soft'] == tokens.primary .. ' / 0.14', 'soft primary')
assert(tokens['primary-foreground'] == '0 0% 100%' or tokens['primary-foreground'] == '0 0% 6.3%', 'primary foreground contrast')

equal(configuredPrimary, '#95FF00', 'theme.json primary is kora green')
equal(tokens.primary, '84.9 100% 50%', 'default primary HSL')
equal(tokens['primary-foreground'], '0 0% 6.3%', 'dark text on kora green')
equal(tokens['brand-hover'], '84.9 100% 44.9%', 'brand hover derives from green')
equal(KoraThemeFile.name, 'Kora green', 'primary name comes from theme.json')
equal(KoraThemeFile.presets[1].label, 'Crimson', 'presets come from theme.json')
equal(QBThemeConfig.colors, nil, 'config.lua holds no colours')
local crimson = registered.getTokens('#DC143C')
equal(crimson['primary-foreground'], '0 0% 100%', 'crimson preset keeps white text')

local violet = registered.getTokens('#7C3AED')
equal(violet.primary, '262.1 83.3% 57.8%', 'string primary override')
equal(violet.background, tokens.background, 'primary override keeps background')

local light = registered.getTokens({ primary = '#FDE047', background = '#000000' })
equal(light['primary-foreground'], '0 0% 6.3%', 'light-primary foreground')
equal(light.background, '0 0% 0%', 'semantic table override')

local invalid = registered.getTokens({ primary = 'red' })
equal(invalid.primary, tokens.primary, 'invalid override falls back')

local semantic = registered.getTokens({ danger = '#AA0000', surfaceRaised = '#303030', unapproved = '#FFFFFF' })
equal(semantic.destructive, '0 100% 33.3%', 'danger semantic override')
equal(semantic['surface-raised'], '0 0% 18.8%', 'surface semantic override')
equal(semantic.unapproved, nil, 'unapproved roles are ignored')
equal(registered.getTokens(42).primary, tokens.primary, 'malformed override container is ignored')
equal(tokens.ring, tokens.primary, 'focus ring derives from primary')
equal(tokens.danger, tokens.destructive, 'danger alias matches destructive')
equal(tokens.armour, '209.7 100% 61.6%', 'armour remains distinct')
equal(tokens.popover, '0 0% 10.6%', 'popover preserves the canonical toast surface')

local css = assert(io.open(root .. 'theme.css', 'r')):read('*a')
assert(not css:find('--primary:', 1, true), 'theme.css must not define palette variables')
assert(css:find('--font-sans:', 1, true), 'theme.css keeps fixed non-colour tokens')
assert(css:find('::%-webkit%-scrollbar%-thumb'), 'theme.css must define thumb-only scrollbars')

-- Single source of truth: changing theme.json changes every Lua output.
local function boot(files)
    local out = {}
    _G.exports = setmetatable({}, { __call = function(_, name, fn) out[name] = fn end })
    _G.LoadResourceFile = function(_, path) return files[path] end
    _G.KoraThemeFile = nil
    dofile(root .. 'theme_loader.lua')
    dofile(root .. 'shared.lua')
    return out
end

local original = assert(io.open(root .. 'theme.json', 'r')):read('*a')
local fixture = boot({ ['theme.json'] = (original:gsub('#95FF00', '#1E90FF')) })
equal(fixture.getPrimaryColor(), '#1E90FF', 'getPrimaryColor follows theme.json')
equal(fixture.getTokens().primary, '209.6 100% 55.9%', 'getTokens follows theme.json')
equal(fixture.getTokens('#DC143C').primary, '348 83.3% 47.1%', 'overrides still win')

local printed = {}
local realPrint = print
_G.print = function(message) printed[#printed + 1] = message end
local missing = boot({})
equal(missing.getPrimaryColor(), '#95FF00', 'missing theme.json uses the emergency default')
assert(printed[1] and printed[1]:find('^%^3%[kora_theme%]'), 'missing theme.json warns')
printed = {}
local broken = boot({ ['theme.json'] = '{ not json' })
equal(broken.getPrimaryColor(), '#95FF00', 'invalid theme.json uses the emergency default')
assert(printed[1] and printed[1]:find('^%^3%[kora_theme%]'), 'invalid theme.json warns')
printed = {}
local partial = boot({ ['theme.json'] = '{"colors":{"primary":"#123456","danger":"red"}}' })
equal(partial.getPrimaryColor(), '#123456', 'valid keys still come from theme.json')
equal(KoraThemeFile.colours.danger, '#EF4444', 'invalid key falls back to the emergency default')
assert(#printed >= 1, 'invalid key warns')
_G.print = realPrint

-- No duplicated palette outside theme.json (and the loader's emergency table).
local function read(path) return assert(io.open(root .. path, 'r')):read('*a') end
for _, path in ipairs({ 'config.lua', 'shared.lua', 'client/main.lua', 'client/bridge.lua', 'theme.js', 'theme.css', 'vite-plugin.mjs' }) do
    local source = read(path):gsub("Use a six%-digit hex colour such as #7C3AED, or reset%.", '')
    assert(not source:find('#%x%x%x%x%x%x'), path .. ' must not embed colour hex values')
end

print('qbtheme: 40 assertions passed')
