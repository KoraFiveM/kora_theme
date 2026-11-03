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

equal(configuredPrimary, '#A8FF00', 'theme.json primary is kora green')
equal(tokens.primary, '80.5 100% 50%', 'default primary HSL')
equal(tokens['primary-foreground'], '0 0% 6.3%', 'dark text on kora green')
equal(tokens['brand-hover'], '80.5 100% 44.9%', 'brand hover derives from green')
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

local catalogJson = assert(io.open(root .. 'fonts/catalog.json', 'r')):read('*a')
local original = assert(io.open(root .. 'theme.json', 'r')):read('*a')
local fixture = boot({ ['theme.json'] = (original:gsub('#A8FF00', '#1E90FF')), ['fonts/catalog.json'] = catalogJson })
equal(fixture.getPrimaryColor(), '#1E90FF', 'getPrimaryColor follows theme.json')
equal(fixture.getTokens().primary, '209.6 100% 55.9%', 'getTokens follows theme.json')
equal(fixture.getTokens('#DC143C').primary, '348 83.3% 47.1%', 'overrides still win')

local printed = {}
local realPrint = print
_G.print = function(message) printed[#printed + 1] = message end
local missing = boot({})
equal(missing.getPrimaryColor(), '#A8FF00', 'missing theme.json uses the emergency default')
assert(printed[1] and printed[1]:find('^%^3%[kora_theme%]'), 'missing theme.json warns')
printed = {}
local broken = boot({ ['theme.json'] = '{ not json' })
equal(broken.getPrimaryColor(), '#A8FF00', 'invalid theme.json uses the emergency default')
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

-- Fonts: theme.json "fonts" + fonts/catalog.json, overridden by QBThemeConfig.fonts.
local fontAssertions = 0
local function check(actual, expected, message) fontAssertions = fontAssertions + 1 equal(actual, expected, message) end
local catalog = json.decode(catalogJson)
local cssDefault = function(name) return css:match('%-%-' .. name:gsub('%-', '%%-') .. ':%s*([^;]+);') end
check(cssDefault('font-sans'), catalog.defaults.sans, 'theme.css --font-sans matches the catalog default')
check(cssDefault('font-heading'), catalog.defaults.sans, 'theme.css --font-heading defaults to the body stack')
check(cssDefault('font-mono'), catalog.defaults.mono, 'theme.css --font-mono matches the catalog default')
check(cssDefault('font-sans'), 'Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif', 'default body stack is unchanged')
check(cssDefault('font-mono'), '"SFMono-Regular", Consolas, "Liberation Mono", monospace', 'default mono stack is unchanged')
check(css:find('@import url("fonts/fonts.css");', 1, true) ~= nil, true, 'theme.css imports the bundled fonts')
check(css:find(':where(h1, h2, h3, h4, h5, h6) { font-family: var(--font-heading); }', 1, true) ~= nil, true, 'headings use --font-heading')
check(read('shared.lua'):find('Inter, ui%-sans%-serif'), nil, 'shared.lua does not hardcode the font stack')

local fontsCss = read('fonts/fonts.css')
local faces = {}
for block in fontsCss:gmatch('@font%-face%s*(%b{})') do
    local family = block:match('font%-family:%s*"([^"]+)"')
    local url = block:match('url%("([^"]+)"%)')
    check(block:find('font-display: swap;', 1, true) ~= nil, true, family .. ' uses font-display swap')
    check(url:match('^[a-z0-9-]+/[a-z0-9-]+%.woff2$') ~= nil, true, family .. ' uses a relative woff2 url')
    check(io.open(root .. 'fonts/' .. url, 'rb') ~= nil, true, url .. ' exists')
    faces[family] = true
end
for _, font in ipairs(catalog.fonts) do
    check(faces[font.family], true, font.id .. ' has an @font-face rule')
    check(font.stack:sub(1, #font.family + 2), '"' .. font.family .. '"', font.id .. ' stack starts with its bundled family')
    check(font.family:sub(1, 5), 'Kora ', font.id .. ' family is prefixed so the default stack never changes')
    check(read('fonts/' .. font.id .. '/OFL.txt'):find('SIL Open Font License, Version 1.1', 1, true) ~= nil, true, font.id .. ' ships its OFL licence')
end

check(read('fxmanifest.lua'):find("'fonts/**',", 1, true) ~= nil, true, 'fxmanifest ships the fonts folder')

local defaults = registered.getFonts()
check(KoraThemeFile.fonts.body, 'default', 'theme.json body font defaults')
check(defaults.body.stack, catalog.defaults.sans, 'default body stack')
check(defaults.heading.stack, catalog.defaults.sans, 'default heading stack')
check(defaults.mono.stack, catalog.defaults.mono, 'default mono stack')
check(defaults.body.source, 'default', 'default body source')
check(tokens['font-sans'], catalog.defaults.sans, 'getTokens font-sans')
check(tokens['font-heading'], catalog.defaults.sans, 'getTokens font-heading')
check(tokens['font-mono'], catalog.defaults.mono, 'getTokens font-mono')

local function withFonts(fonts)
    local themed = original:gsub('"presets"', ('"fonts": %s,\n  "presets"'):format(fonts), 1)
    return boot({ ['theme.json'] = themed, ['fonts/catalog.json'] = catalogJson })
end
printed = {}
_G.print = function(message) printed[#printed + 1] = message end
local themed = withFonts('{ "heading": "oswald", "body": "Poppins", "mono": "jetbrains-mono" }')
local themedFonts = themed.getFonts()
check(themedFonts.body.id, 'poppins', 'theme.json catalog id (case-insensitive)')
check(themedFonts.body.source, 'theme.json', 'theme.json font source')
check(themedFonts.heading.stack, catalog.fonts[6].stack, 'theme.json heading stack')
check(themedFonts.mono.id, 'jetbrains-mono', 'theme.json mono id')
check(themed.getTokens()['font-sans'], themedFonts.body.stack, 'getTokens follows theme.json fonts')
check(#printed, 0, 'valid fonts do not warn')

local followed = withFonts('{ "body": "roboto" }').getFonts()
check(followed.heading.stack, followed.body.stack, 'default heading follows the body font')
check(followed.heading.source, 'default', 'unset heading reports the default source')

local custom = withFonts('{ "body": "Arial, \\"Helvetica Neue\\", sans-serif", "heading": "url(evil)", "mono": "a;}body{" }')
check(KoraThemeFile.fonts.body, 'Arial, "Helvetica Neue", sans-serif', 'custom family list accepted')
check(custom.getFonts().body.id, 'custom', 'custom font id')
check(custom.getFonts().body.stack, 'Arial, "Helvetica Neue", sans-serif, ' .. catalog.defaults.sans, 'custom stack keeps the default fallbacks')
check(KoraThemeFile.fonts.heading, 'default', 'url() is rejected')
check(KoraThemeFile.fonts.mono, 'default', 'CSS syntax is rejected')
check(#printed, 2, 'each rejected font warns')
check(printed[1]:find('^%^3%[kora_theme%]') ~= nil, true, 'font warnings use the theme.json style')
check(KoraThemeFile.resolveFont(('a'):rep(201), 'sans'), nil, 'overlong family rejected')
check(KoraThemeFile.resolveFont('"Unbalanced', 'sans'), nil, 'unbalanced quotes rejected')
check(KoraThemeFile.resolveFont('<style>', 'sans'), nil, 'angle brackets rejected')
check(KoraThemeFile.resolveFont('123', 'sans'), nil, 'family needs a letter')
printed = {}
withFonts('"poppins"')
check(#printed, 1, 'non-object fonts warns')
check(KoraThemeFile.fonts.body, 'default', 'non-object fonts falls back')
printed = {}
local noCatalog = boot({ ['theme.json'] = (original:gsub('"presets"', '"fonts": { "body": "poppins" },\n  "presets"', 1)) })
check(noCatalog.getFonts().mono.stack, catalog.defaults.mono, 'missing catalog keeps the emergency defaults')
check(noCatalog.getFonts().body.id, 'custom', 'missing catalog treats ids as plain family names')
_G.print = realPrint

-- /config overrides win over theme.json; custom family lists win over the dropdown.
withFonts('{ "heading": "oswald", "body": "poppins" }')
QBThemeConfig.fonts = { heading = 'theme', body = 'roboto', mono = 'roboto-mono', custom = { heading = '', body = '', mono = '' } }
local configured = registered.getFonts()
check(configured.body.id, 'roboto', 'config dropdown overrides theme.json')
check(configured.body.source, 'config', 'config source')
check(configured.heading.id, 'oswald', "'theme' follows theme.json")
check(configured.mono.id, 'roboto-mono', 'config mono')
QBThemeConfig.fonts.custom.body = 'Comic Sans MS'
QBThemeConfig.fonts.heading = 'default'
configured = registered.getFonts()
check(configured.body.stack, 'Comic Sans MS, ' .. catalog.defaults.sans, 'custom family overrides the dropdown')
check(configured.heading.stack, configured.body.stack, "config 'default' heading follows the body font")
check(configured.heading.source, 'config', 'explicit default heading is a config choice')
_G.print = function() end
QBThemeConfig.fonts.custom.body = 'x;}'
QBThemeConfig.fonts.mono = 'not-a-font!'
configured = registered.getFonts()
_G.print = realPrint
check(configured.body.id, 'roboto', 'invalid custom family falls back to the dropdown')
check(configured.mono.stack, catalog.defaults.mono, 'invalid dropdown value falls back to theme.json/default')
check(registered.getTokens()['font-sans'], configured.body.stack, 'getTokens uses config fonts')

print(('qbtheme: %d assertions passed'):format(40 + fontAssertions))
