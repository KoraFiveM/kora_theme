local root = debug.getinfo(1, 'S').source:sub(2):match('(.*/)') .. '../'
local callbacks, handlers, sent = {}, {}, {}
local lastOverrides
local playerTheme = '#22C55E'

_G.exports = {
    kora_theme = {
        getTokens = function(_, overrides)
            lastOverrides = overrides
            return { primary = overrides == '#7C3AED' and '262.1 83.3% 57.8%' or '348 83.3% 47.1%' }
        end,
        getPlayerTheme = function() return playerTheme end,
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
equal(sent[#sent].action, 'qbtheme:override', 'apply message action')
equal(sent[#sent].data, '#7C3AED', 'apply message carries the raw override')

QBTheme.refresh()
equal(lastOverrides, '#7C3AED', 'refresh retains cached override')

local response
callbacks['qbtheme:ready']({}, function(value) response = value end)
equal(response.overrides, '#7C3AED', 'ready returns the effective resource override')

local before = #sent
handlers.onClientResourceStart('unrelated')
equal(#sent, before, 'unrelated restart ignored')
handlers.onClientResourceStart('kora_theme')
equal(#sent, before + 2, 'qbtheme restart reloads and reapplies tokens')
equal(lastOverrides, '#7C3AED', 'restart retains cached override')
equal(sent[#sent - 1].action, 'qbtheme:refresh', 'restart reloads theme.json')
equal(sent[#sent].action, 'qbtheme:override', 'restart reapplies effective override')

QBTheme.apply({ warning = '#F59E0B' })
equal(type(lastOverrides), 'table', 'semantic table override cached')
equal(lastOverrides.warning, '#F59E0B', 'semantic table forwarded')
equal(lastOverrides.primary, '#22C55E', 'player preference supplies primary for semantic override')

playerTheme = '#3B82F6'
handlers['qbtheme:playerThemeChanged']()
equal(lastOverrides.primary, '#3B82F6', 'player theme event refreshes consumer primary')
equal(sent[#sent].action, 'qbtheme:override', 'player theme event updates browser')

print('qbtheme bridge: 14 assertions passed')
