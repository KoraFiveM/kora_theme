local root = debug.getinfo(1, 'S').source:sub(2):match('(.*/)') .. '../'
local callbacks, handlers, sent = {}, {}, {}
local lastOverrides
local playerTheme = '#22C55E'
local fonts = { body = { id = 'default', stack = 'Inter, sans-serif', source = 'default' } }

_G.exports = {
    kora_theme = {
        getTokens = function(_, overrides)
            lastOverrides = overrides
            return { primary = overrides == '#7C3AED' and '262.1 83.3% 57.8%' or '348 83.3% 47.1%' }
        end,
        getPlayerTheme = function() return playerTheme end,
        getFonts = function() return fonts end,
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

KoraTheme.apply('#7C3AED')
equal(lastOverrides, '#7C3AED', 'apply forwards override')
equal(sent[#sent].action, 'kora_theme:override', 'apply message action')
equal(sent[#sent].data, '#7C3AED', 'apply message carries the raw override')

KoraTheme.refresh()
equal(lastOverrides, '#7C3AED', 'refresh retains cached override')

local response
callbacks['kora_theme:ready']({}, function(value) response = value end)
equal(response.overrides, '#7C3AED', 'ready returns the effective resource override')
equal(response.fonts, fonts, 'ready returns the resolved server fonts')

local before = #sent
handlers.onClientResourceStart('unrelated')
equal(#sent, before, 'unrelated restart ignored')
handlers.onClientResourceStart('kora_theme')
equal(#sent, before + 3, 'kora_theme restart reloads and reapplies tokens and fonts')
equal(lastOverrides, '#7C3AED', 'restart retains cached override')
equal(sent[#sent - 2].action, 'kora_theme:refresh', 'restart reloads theme.json')
equal(sent[#sent - 1].action, 'kora_theme:override', 'restart reapplies effective override')
equal(sent[#sent].action, 'kora_theme:fonts', 'restart resends the server fonts')

KoraTheme.apply({ warning = '#F59E0B' })
equal(type(lastOverrides), 'table', 'semantic table override cached')
equal(lastOverrides.warning, '#F59E0B', 'semantic table forwarded')
equal(lastOverrides.primary, '#22C55E', 'player preference supplies primary for semantic override')

playerTheme = '#3B82F6'
handlers['kora_theme:playerThemeChanged']()
equal(lastOverrides.primary, '#3B82F6', 'player theme event refreshes consumer primary')
equal(sent[#sent].action, 'kora_theme:override', 'player theme event updates browser')

fonts = { body = { id = 'poppins', stack = '"Kora Poppins", sans-serif', source = 'config' } }
handlers['kora_theme:fontsChanged']()
equal(sent[#sent].action, 'kora_theme:fonts', 'font change message action')
equal(sent[#sent].data.body.id, 'poppins', 'font change forwards the resolved fonts')
equal(KoraTheme.fonts(), fonts, 'KoraTheme.fonts reads the provider export')

print('kora_theme bridge: 20 assertions passed')
