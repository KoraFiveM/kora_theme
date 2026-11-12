-- This file is imported into each UI-owning resource. It deliberately runs in
-- the consumer's Lua VM so raw NUI natives target that consumer's frame.
local PROVIDER = 'kora_theme'
local currentOverrides
local playerOverride

KoraTheme = KoraTheme or {}

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
    print(('[%s] could not read kora_theme tokens: %s'):format(GetCurrentResourceName(), tostring(result)))
    return {}
end

function KoraTheme.apply(overrides)
    currentOverrides = overrides or nil
    local result = tokens()
    -- The browser reads the base palette directly from kora_theme/theme.json.
    -- Sending the Lua-derived complete token map here would overwrite that
    -- palette on clients, where LoadResourceFile is unavailable. Only an
    -- approved resource-specific override crosses this bridge.
    SendNUIMessage({ action = 'kora_theme:override', data = effectiveOverrides() })
    return result
end

function KoraTheme.refresh()
    local result = tokens()
    SendNUIMessage({ action = 'kora_theme:refresh' })
    return result
end

KoraTheme.tokens = tokens

---Resolved server fonts from kora_theme (theme.json plus /config overrides).
function KoraTheme.fonts()
    local ok, result = pcall(function()
        return exports[PROVIDER]:getFonts()
    end)
    return ok and type(result) == 'table' and result or nil
end

local function sendFonts()
    SendNUIMessage({ action = 'kora_theme:fonts', data = KoraTheme.fonts() })
end

RegisterNUICallback('kora_theme:ready', function(_, cb)
    -- theme.js loads the provider's static theme.json itself; this response
    -- only adds the player's saved preference, any consumer-owned accent and
    -- the resolved server fonts (which include /config overrides).
    readPlayerOverride()
    cb({ overrides = effectiveOverrides(), fonts = KoraTheme.fonts() })
end)

-- Raised by kora_theme when an admin changes a font in /config.
AddEventHandler('kora_theme:fontsChanged', sendFonts)

AddEventHandler('kora_theme:playerThemeChanged', function()
    readPlayerOverride()
    KoraTheme.apply(currentOverrides)
end)

AddEventHandler('onClientResourceStart', function(resource)
    if resource ~= PROVIDER then return end
    SetTimeout(0, function()
        readPlayerOverride()
        KoraTheme.refresh()
        KoraTheme.apply(currentOverrides)
        sendFonts()
    end)
end)

readPlayerOverride()
