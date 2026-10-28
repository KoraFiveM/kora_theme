-- This file is imported into each UI-owning resource. It deliberately runs in
-- the consumer's Lua VM so raw NUI natives target that consumer's frame.
local PROVIDER = 'kora_theme'
local currentOverrides
local playerOverride

QBTheme = QBTheme or {}

local function effectiveOverrides()
    if not playerOverride then return currentOverrides end
    if type(currentOverrides) == 'string' then return currentOverrides end
    if type(currentOverrides) ~= 'table' then return playerOverride end

    local merged = { primary = playerOverride }
    for key, value in pairs(currentOverrides) do merged[key] = value end
    return merged
end

local function readPlayerOverride()
    local ok, result = pcall(function()
        return exports[PROVIDER]:getPlayerTheme()
    end)
    playerOverride = ok and type(result) == 'string' and result or nil
end

local function tokens()
    local ok, result = pcall(function()
        return exports[PROVIDER]:getTokens(effectiveOverrides())
    end)
    if ok and type(result) == 'table' then return result end
    print(('[%s] could not read qbtheme tokens: %s'):format(GetCurrentResourceName(), tostring(result)))
    return {}
end

function QBTheme.apply(overrides)
    currentOverrides = overrides or nil
    local result = tokens()
    -- The browser reads the base palette directly from kora_theme/theme.json.
    -- Sending the Lua-derived complete token map here would overwrite that
    -- palette on clients, where LoadResourceFile is unavailable. Only an
    -- approved resource-specific override crosses this bridge.
    SendNUIMessage({ action = 'qbtheme:override', data = effectiveOverrides() })
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
    -- theme.js loads the provider's static theme.json itself; this response
    -- only adds the player's saved preference and any consumer-owned accent.
    readPlayerOverride()
    cb({ overrides = effectiveOverrides() })
end)

AddEventHandler('qbtheme:playerThemeChanged', function()
    readPlayerOverride()
    QBTheme.apply(currentOverrides)
end)

AddEventHandler('onClientResourceStart', function(resource)
    if resource ~= PROVIDER then return end
    SetTimeout(0, function()
        readPlayerOverride()
        QBTheme.refresh()
        QBTheme.apply(currentOverrides)
    end)
end)

readPlayerOverride()
