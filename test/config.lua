-- config.lua registers KoraThemeConfig with kora_lib's /config bridge. Runs the
-- registration against a recording bridge, and against the real kora_lib
-- consumer bridge when a kora_lib checkout sits next to this resource.
local root = debug.getinfo(1, 'S').source:sub(2):match('(.*/)') .. '../'
local assertions = 0
local function equal(actual, expected, message)
    assertions = assertions + 1
    if actual ~= expected then error(('%s: expected %s, got %s'):format(message, tostring(expected), tostring(actual)), 2) end
end
local function read(path)
    local file = io.open(path, 'r')
    if not file then return nil end
    local content = file:read('*a')
    file:close()
    return content
end

local events, registered = {}, {}
local bridgeSource
_G.exports = setmetatable({}, { __call = function(_, name, fn) registered[name] = fn end })
_G.GetCurrentResourceName = function() return 'kora_theme' end
_G.GetResourceState = function(name) return name == 'kora_lib' and 'started' or 'missing' end
_G.SetTimeout = function(_, fn) fn() end
_G.TriggerEvent = function(name, ...) events[#events + 1] = { name = name, args = { ... } } end
_G.LoadResourceFile = function(resource, path)
    if resource == 'kora_lib' then return bridgeSource end
    return read(root .. path)
end
dofile(root .. 'test/json.lua')
dofile(root .. 'theme_loader.lua')

-- Recording bridge: captures descriptors, change handlers and the adopted table.
local recorded = { onChange = {} }
_G.RecordingBridge = {
    enum = function(value, options) return { kind = 'enum', value = value, options = options } end,
    string = function(value, options) return { kind = 'string', value = value, options = options } end,
    onChange = function(path, handler) recorded.onChange[path] = handler end,
    adopt = function(values)
        recorded.adopted = values
        local plain = {}
        for key, value in pairs(values) do plain[key] = value end
        plain.fonts = { custom = {} }
        for slot, field in pairs(values.fonts) do
            if slot ~= 'custom' then plain.fonts[slot] = field.value end
        end
        for slot, field in pairs(values.fonts.custom) do plain.fonts.custom[slot] = field.value end
        return plain
    end,
}
bridgeSource = 'return function() return RecordingBridge end'
dofile(root .. 'config.lua')

local fonts = recorded.adopted.fonts
for _, slot in ipairs({ 'heading', 'body', 'mono' }) do
    equal(fonts[slot].kind, 'enum', slot .. ' is a dropdown')
    equal(fonts[slot].value, 'theme', slot .. ' defaults to theme.json')
    equal(fonts[slot].options.live, true, slot .. ' applies live')
    equal(fonts[slot].options.scope, nil, slot .. ' uses the shared (client-synchronised) scope')
    equal(fonts[slot].options.options[1].value, 'theme', slot .. ' lists the theme.json choice first')
    equal(fonts[slot].options.options[1].label, 'Server default (theme.json)', slot .. ' theme.json label')
    equal(fonts.custom[slot].kind, 'string', slot .. ' has a custom family field')
    equal(fonts.custom[slot].value, '', slot .. ' custom family is empty by default')
    equal(fonts.custom[slot].options.live, true, slot .. ' custom family applies live')
    equal(fonts.custom[slot].options.advanced, true, slot .. ' custom family is advanced')
    equal(fonts.custom[slot].options.maxLength, 200, slot .. ' custom family length is bounded')
    equal(('Arial, "Segoe UI"'):match(fonts.custom[slot].options.pattern) ~= nil, true, slot .. ' pattern accepts family lists')
    equal(('x;}body{'):match(fonts.custom[slot].options.pattern), nil, slot .. ' pattern rejects CSS syntax')
    equal(('url(x)'):match(fonts.custom[slot].options.pattern), nil, slot .. ' pattern rejects url()')
    equal(type(recorded.onChange['fonts.' .. slot]), 'function', slot .. ' change handler registered')
    equal(type(recorded.onChange['fonts.custom.' .. slot]), 'function', slot .. ' custom change handler registered')
end
local labels = {}
for _, option in ipairs(fonts.body.options.options) do labels[option.value] = option.label end
equal(labels.poppins, 'Poppins', 'body dropdown lists catalog labels')
equal(labels['jetbrains-mono'], 'JetBrains Mono', 'body dropdown also lists monospace fonts')
local monoValues = {}
for _, option in ipairs(fonts.mono.options.options) do monoValues[option.value] = true end
equal(monoValues.poppins, nil, 'monospace dropdown lists only monospace fonts')
equal(monoValues['roboto-mono'], true, 'monospace dropdown lists Roboto Mono')
equal(KoraThemeConfig.fonts.body, 'theme', 'adopted plain table keeps the font values')
equal(KoraThemeConfig.playerTheme.command, 'theme', 'adopted table keeps playerTheme')

recorded.onChange['fonts.body']('poppins', 'theme')
equal(events[#events].name, 'kora_theme:fontsChanged', 'font change raises the local fonts event')

-- Real kora_lib bridge (client realm): the schema validates and a live
-- /config update rewrites KoraThemeConfig.fonts and raises the fonts event.
local realBridge = read(root .. '../kora_lib/modules/config/consumer.lua')
if realBridge then
    local netHandlers = {}
    _G.IsDuplicityVersion = function() return false end
    _G.TriggerServerEvent = function() end
    _G.RegisterNetEvent = function(name, handler) netHandlers[name] = handler end
    _G.AddEventHandler = function() end
    bridgeSource = realBridge
    KoraThemeConfig = nil
    dofile(root .. 'config.lua')
    equal(KoraThemeConfig.fonts.heading, 'theme', 'real bridge adopts the heading default')
    equal(KoraThemeConfig.fonts.custom.mono, '', 'real bridge adopts the custom defaults')
    dofile(root .. 'shared.lua')
    events = {}
    netHandlers['kora_lib:client:configUpdated']('kora_theme', { 'fonts', 'body' }, 'oswald', 2)
    equal(KoraThemeConfig.fonts.body, 'oswald', 'live update writes KoraThemeConfig.fonts.body')
    equal(events[#events] and events[#events].name, 'kora_theme:fontsChanged', 'live update raises the fonts event')
    equal(registered.getFonts().body.id, 'oswald', 'getFonts follows the live update')
    netHandlers['kora_lib:client:configUpdated']('kora_theme', { 'fonts', 'custom', 'body' }, 'Arial', 3)
    equal(registered.getFonts().body.stack:sub(1, 7), 'Arial, ', 'custom family overrides the dropdown live')
    print(('kora_theme config: %d assertions passed (with kora_lib bridge)'):format(assertions))
else
    print(('kora_theme config: %d assertions passed (kora_lib not found; real bridge skipped)'):format(assertions))
end
