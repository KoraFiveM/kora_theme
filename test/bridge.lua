local root = debug.getinfo(1, 'S').source:sub(2):match('(.*/)') .. '../'
local callbacks, handlers, sent = {}, {}, {}
local lastOverrides

_G.exports = {
    qbtheme = {
        getTokens = function(_, overrides)
            lastOverrides = overrides
            return { primary = overrides == '#7C3AED' and '262.1 83.3% 57.8%' or '348 83.3% 47.1%' }
        end,
    },
}
_G.GetCurrentResourceName = function() return 'consumer' end
_G.RegisterNUICallback = function(name, fn) callbacks[name] = fn end
_G.AddEventHandler = function(name, fn) handlers[name] = fn end
_G.SetTimeout = function(_, fn) fn() end
_G.SendNUIMessage = function(message) sent[#sent + 1] = message end

dofile(root .. 'client/bridge.lua')

local function equal(actual, expected, message)
    if actual ~= expected then error(('%s: expected %s, got %s'):format(message, tostring(expected), tostring(actual)), 2) end
end

QBTheme.apply('#7C3AED')
equal(lastOverrides, '#7C3AED', 'apply forwards override')
equal(sent[#sent].action, 'qbtheme:tokens', 'apply message action')
equal(sent[#sent].data.primary, '262.1 83.3% 57.8%', 'apply message tokens')

QBTheme.refresh()
equal(lastOverrides, '#7C3AED', 'refresh retains cached override')

local response
callbacks['qbtheme:ready']({}, function(value) response = value end)
equal(response.primary, '262.1 83.3% 57.8%', 'ready returns cached override tokens')

local before = #sent
handlers.onClientResourceStart('unrelated')
equal(#sent, before, 'unrelated restart ignored')
handlers.onClientResourceStart('qbtheme')
equal(#sent, before + 1, 'qbtheme restart reapplies tokens')
equal(lastOverrides, '#7C3AED', 'restart retains cached override')

QBTheme.apply({ warning = '#F59E0B' })
equal(type(lastOverrides), 'table', 'semantic table override cached')
equal(lastOverrides.warning, '#F59E0B', 'semantic table forwarded')

print('qbtheme bridge: 9 assertions passed')
