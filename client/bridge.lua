-- This file is imported into each UI-owning resource. It deliberately runs in
-- the consumer's Lua VM so raw NUI natives target that consumer's frame.
local PROVIDER = 'qbtheme'
local currentOverrides

QBTheme = QBTheme or {}

local function tokens()
    local ok, result = pcall(function()
        return exports[PROVIDER]:getTokens(currentOverrides)
    end)
    if ok and type(result) == 'table' then return result end
    print(('[%s] could not read qbtheme tokens: %s'):format(GetCurrentResourceName(), tostring(result)))
    return {}
end

function QBTheme.apply(overrides)
    currentOverrides = overrides or nil
    local result = tokens()
    -- The browser reads the base palette directly from qbtheme/theme.json.
    -- Sending the Lua-derived complete token map here would overwrite that
    -- palette on clients, where LoadResourceFile is unavailable. Only an
    -- approved resource-specific override crosses this bridge.
    SendNUIMessage({ action = 'qbtheme:override', data = currentOverrides })
    return result
end

function QBTheme.refresh()
    local result = tokens()
    SendNUIMessage({ action = 'qbtheme:refresh' })
    return result
end

function QBTheme.tokens()
    return tokens()
end

RegisterNUICallback('qbtheme:ready', function(_, cb)
    -- theme.js loads the provider's static theme.json itself. Keep this
    -- callback for consumers built against the old bridge without giving a
    -- client-side Lua fallback precedence over the JSON palette.
    cb({})
end)

AddEventHandler('onClientResourceStart', function(resource)
    if resource ~= PROVIDER then return end
    SetTimeout(0, QBTheme.refresh)
end)
