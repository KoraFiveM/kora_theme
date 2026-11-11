local root = debug.getinfo(1, 'S').source:sub(2):match('(.*/)') .. '../'
local callbacks, commands, handlers, events, messages, focus = {}, {}, {}, {}, {}, {}
local kvp = { ['kora_theme:playerTheme'] = '#7c3aed' }
local registered = {}

_G.exports = setmetatable({}, {
    __call = function(_, name, fn) registered[name] = fn end,
    __index = function(_, resource)
        if resource == 'kora_theme' then return { getFonts = function() return registered.getFonts() end } end
    end,
})
_G.GetCurrentResourceName = function() return 'kora_theme' end
_G.LoadResourceFile = function(_, path)
    local file = assert(io.open(root .. path, 'r'))
    local content = file:read('*a')
    file:close()
    return content
end
_G.GetResourceKvpString = function(key) return kvp[key] end
_G.SetResourceKvp = function(key, value) kvp[key] = value end
_G.DeleteResourceKvp = function(key) kvp[key] = nil end
_G.RegisterNUICallback = function(name, fn) callbacks[name] = fn end
_G.RegisterCommand = function(name, fn) commands[name] = fn end
_G.AddEventHandler = function(name, fn) handlers[name] = fn end
_G.TriggerEvent = function(name, ...) events[#events + 1] = { name = name, args = { ... } } end
_G.SendNUIMessage = function(message) messages[#messages + 1] = message end
_G.SetNuiFocus = function(keyboard, cursor) focus[#focus + 1] = { keyboard, cursor } end

dofile(root .. 'test/json.lua')
dofile(root .. 'theme_loader.lua')
dofile(root .. 'config.lua')
dofile(root .. 'shared.lua')
dofile(root .. 'client/main.lua')

local assertions = 0
local function equal(actual, expected, message)
    assertions = assertions + 1
    if actual ~= expected then error(('%s: expected %s, got %s'):format(message, tostring(expected), tostring(actual)), 2) end
end

equal(registered.getPlayerTheme(), '#7C3AED', 'saved theme loads and normalises')
equal(type(commands.theme), 'function', 'theme command registered by default')
local suggestionCount = #events
handlers.onClientResourceStart('kora_chat')
equal(#events, suggestionCount + 1, 'chat restart restores command suggestion')
equal(events[#events].name, 'chat:addSuggestion', 'chat restart publishes suggestion')

commands.theme(0, {})
equal(focus[#focus][1], true, 'bare command gives keyboard focus')
equal(messages[#messages].action, 'kora_theme:open', 'bare command opens picker')
equal(messages[#messages].data.selected, '#7C3AED', 'picker receives saved theme')

commands.theme(0, { '22c55e' })
equal(kvp['kora_theme:playerTheme'], '#22C55E', 'command saves normalised colour')
equal(registered.getPlayerTheme(), '#22C55E', 'command updates current theme')
equal(events[#events].name, 'kora_theme:playerThemeChanged', 'command announces theme change')

callbacks['kora_theme:close']({}, function() end)
local openCount = #messages
commands.theme(0, {}, 'theme')
equal(messages[#messages].action, 'kora_theme:open', 'bare raw command still opens picker')
callbacks['kora_theme:close']({}, function() end)
-- The console drops a '#'-prefixed word from args; the raw line still has it.
commands.theme(0, {}, 'theme #3b82f6')
equal(registered.getPlayerTheme(), '#3B82F6', 'hash colour is read from the raw command')
equal(#messages > openCount, true, 'raw colour command announces the change')
commands.theme(0, { '22c55e' })
commands.theme(0, {}) -- leave the picker open as before for the checks below

local result
callbacks['kora_theme:set']({ colour = '#F97316' }, function(value) result = value end)
equal(result.ok, true, 'picker accepts a valid colour')
equal(kvp['kora_theme:playerTheme'], '#F97316', 'picker persists valid colour')

callbacks['kora_theme:set']({ colour = 'orange' }, function(value) result = value end)
equal(result.ok, false, 'picker rejects malformed colour')
equal(kvp['kora_theme:playerTheme'], '#F97316', 'malformed colour does not replace KVP')

commands.theme(0, { 'reset' })
equal(kvp['kora_theme:playerTheme'], nil, 'reset deletes saved theme')
equal(registered.getPlayerTheme(), nil, 'reset restores default state')

local ready
callbacks['kora_theme:ready']({}, function(value) ready = value end)
equal(ready.overrides, nil, 'ready response reports server default')
equal(type(ready.picker.presets), 'table', 'ready response includes presets')
equal(ready.picker.presets[1].label, 'Kora green', 'picker lists Kora green first')
equal(ready.picker.default, '#95FF00', 'picker default is theme.json primary')
equal(ready.picker.presets[2].label, 'Crimson', 'picker lists theme.json presets after the default')

equal(ready.fonts.body.stack, KoraThemeFile.fontDefaults.sans, 'ready response includes resolved fonts')

KoraThemeConfig.fonts.body = 'poppins'
handlers['kora_theme:fontsChanged']()
equal(messages[#messages].action, 'kora_theme:fonts', 'font change updates the picker frame')
equal(messages[#messages].data.body.id, 'poppins', 'picker frame receives the configured font')
equal(messages[#messages].data.body.source, 'config', 'picker frame receives the font source')
KoraThemeConfig.fonts.body = 'theme'

callbacks['kora_theme:close']({}, function() end)
equal(focus[#focus][1], false, 'close releases keyboard focus')
equal(messages[#messages].action, 'kora_theme:close', 'close hides picker')

KoraThemeConfig = {
    playerTheme = { enabled = false, command = 'disabledtheme', kvpKey = 'disabled' },
}
commands, callbacks, registered = {}, {}, {}
_G.exports = setmetatable({}, {
    __call = function(_, name, fn) registered[name] = fn end,
})
dofile(root .. 'client/main.lua')
equal(commands.disabledtheme, nil, 'disabled config does not register command')
equal(registered.getPlayerTheme(), nil, 'disabled config ignores player theme')

print(('kora_theme client: %d assertions passed'):format(assertions))
