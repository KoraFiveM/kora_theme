local root = debug.getinfo(1, 'S').source:sub(2):match('(.*/)') .. '../'
local callbacks, commands, handlers, events, messages, focus = {}, {}, {}, {}, {}, {}
local kvp = { ['qbtheme:playerTheme'] = '#7c3aed' }
local registered = {}

_G.exports = setmetatable({}, {
    __call = function(_, name, fn) registered[name] = fn end,
})
_G.GetCurrentResourceName = function() return 'qbtheme' end
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

dofile(root .. 'config.lua')
dofile(root .. 'client/main.lua')

local assertions = 0
local function equal(actual, expected, message)
    assertions = assertions + 1
    if actual ~= expected then error(('%s: expected %s, got %s'):format(message, tostring(expected), tostring(actual)), 2) end
end

equal(registered.getPlayerTheme(), '#7C3AED', 'saved theme loads and normalises')
equal(type(commands.theme), 'function', 'theme command registered by default')
local suggestionCount = #events
handlers.onClientResourceStart('qbchat')
equal(#events, suggestionCount + 1, 'chat restart restores command suggestion')
equal(events[#events].name, 'chat:addSuggestion', 'chat restart publishes suggestion')

commands.theme(0, {})
equal(focus[#focus][1], true, 'bare command gives keyboard focus')
equal(messages[#messages].action, 'qbtheme:open', 'bare command opens picker')
equal(messages[#messages].data.selected, '#7C3AED', 'picker receives saved theme')

commands.theme(0, { '22c55e' })
equal(kvp['qbtheme:playerTheme'], '#22C55E', 'command saves normalised colour')
equal(registered.getPlayerTheme(), '#22C55E', 'command updates current theme')
equal(events[#events].name, 'qbtheme:playerThemeChanged', 'command announces theme change')

local result
callbacks['qbtheme:set']({ colour = '#F97316' }, function(value) result = value end)
equal(result.ok, true, 'picker accepts a valid colour')
equal(kvp['qbtheme:playerTheme'], '#F97316', 'picker persists valid colour')

callbacks['qbtheme:set']({ colour = 'orange' }, function(value) result = value end)
equal(result.ok, false, 'picker rejects malformed colour')
equal(kvp['qbtheme:playerTheme'], '#F97316', 'malformed colour does not replace KVP')

commands.theme(0, { 'reset' })
equal(kvp['qbtheme:playerTheme'], nil, 'reset deletes saved theme')
equal(registered.getPlayerTheme(), nil, 'reset restores default state')

local ready
callbacks['qbtheme:ready']({}, function(value) ready = value end)
equal(ready.overrides, nil, 'ready response reports server default')
equal(type(ready.picker.presets), 'table', 'ready response includes presets')

callbacks['qbtheme:close']({}, function() end)
equal(focus[#focus][1], false, 'close releases keyboard focus')
equal(messages[#messages].action, 'qbtheme:close', 'close hides picker')

QBThemeConfig = {
    colors = { primary = '#123456' },
    playerTheme = { enabled = false, command = 'disabledtheme', kvpKey = 'disabled' },
}
commands, callbacks, registered = {}, {}, {}
_G.exports = setmetatable({}, {
    __call = function(_, name, fn) registered[name] = fn end,
})
dofile(root .. 'client/main.lua')
equal(commands.disabledtheme, nil, 'disabled config does not register command')
equal(registered.getPlayerTheme(), nil, 'disabled config ignores player theme')

print(('qbtheme client: %d assertions passed'):format(assertions))
