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
dofile(root .. 'config.lua')
dofile(root .. 'shared.lua')

local function equal(actual, expected, message)
    if actual ~= expected then error(('%s: expected %s, got %s'):format(message, tostring(expected), tostring(actual)), 2) end
end

local tokens = registered.getTokens()
local json = assert(io.open(root .. 'theme.json', 'r')):read('*a')
local configuredPrimary = assert(json:match('"primary"%s*:%s*"(#%x%x%x%x%x%x)"'))
equal(registered.getPrimaryColor(), configuredPrimary, 'configured primary')
assert(type(tokens.primary) == 'string' and tokens.primary:match('%%') ~= nil, 'primary HSL')
equal(tokens.background, '0 0% 6.3%', 'background HSL')
assert(tokens['brand-soft'] == tokens.primary .. ' / 0.14', 'soft primary')
assert(tokens['primary-foreground'] == '0 0% 100%' or tokens['primary-foreground'] == '0 0% 6.3%', 'primary foreground contrast')

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
assert(css:find('--primary:', 1, true), 'theme.css must define a startup fallback primary')
assert(css:find('::%-webkit%-scrollbar%-thumb'), 'theme.css must define thumb-only scrollbars')

print('qbtheme: 20 assertions passed')
