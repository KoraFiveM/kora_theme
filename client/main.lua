local PLAYER_THEME = type(QBThemeConfig) == 'table' and QBThemeConfig.playerTheme or {}
local ENABLED = PLAYER_THEME.enabled ~= false
local COMMAND = type(PLAYER_THEME.command) == 'string' and PLAYER_THEME.command ~= '' and PLAYER_THEME.command or 'theme'
local KVP_KEY = type(PLAYER_THEME.kvpKey) == 'string' and PLAYER_THEME.kvpKey ~= '' and PLAYER_THEME.kvpKey or 'qbtheme:playerTheme'
local pickerOpen = false
local selectedColour

local function normaliseHex(value)
    if type(value) ~= 'string' then return nil end
    value = value:match('^%s*(.-)%s*$')
    if value:sub(1, 1) ~= '#' and value:match('^%x%x%x%x%x%x$') then value = '#' .. value end
    if not value:match('^#%x%x%x%x%x%x$') then return nil end
    return value:upper()
end

local function serverPrimary()
    return type(KoraThemeFile) == 'table' and normaliseHex(KoraThemeFile.colours.primary) or nil
end

-- The first preset is always the server primary from theme.json, so "default"
-- tracks the file. Further presets come from theme.json's "presets" list.
local function configuredPresets()
    local presets, seen = {}, {}
    local function add(label, colour)
        colour = normaliseHex(colour)
        if colour and type(label) == 'string' and label ~= '' and #label <= 40 and not seen[colour] then
            seen[colour] = true
            presets[#presets + 1] = { label = label, colour = colour }
        end
    end

    if type(KoraThemeFile) ~= 'table' then return presets end
    add(KoraThemeFile.name or 'Server default', serverPrimary())
    for _, preset in ipairs(KoraThemeFile.presets or {}) do add(preset.label, preset.colour) end
    return presets
end

local function getPlayerTheme()
    if not ENABLED then return nil end
    return selectedColour
end

local function pickerState()
    return {
        enabled = ENABLED,
        selected = selectedColour,
        default = serverPrimary(),
        presets = configuredPresets(),
    }
end

local function announceChange()
    -- Every UI-owning resource imports bridge.lua into its own client VM. A
    -- local event reaches each copy without sending this personal preference
    -- to the server or another player.
    TriggerEvent('qbtheme:playerThemeChanged')
    SendNUIMessage({ action = 'qbtheme:override', data = selectedColour })
    SendNUIMessage({ action = 'qbtheme:state', data = pickerState() })
end

local function setPlayerTheme(value)
    if not ENABLED then return false, 'Player themes are disabled on this server.' end

    if value == nil or value == '' or value == 'reset' or value == 'default' then
        DeleteResourceKvp(KVP_KEY)
        selectedColour = nil
        announceChange()
        return true
    end

    local colour = normaliseHex(value)
    if not colour then return false, 'Use a six-digit hex colour such as #7C3AED, or reset.' end

    SetResourceKvp(KVP_KEY, colour)
    selectedColour = colour
    announceChange()
    return true
end

local function closePicker()
    if not pickerOpen then return end
    pickerOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'qbtheme:close' })
end

local function openPicker()
    if pickerOpen then return end
    pickerOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'qbtheme:open', data = pickerState() })
end

if ENABLED then selectedColour = normaliseHex(GetResourceKvpString(KVP_KEY)) end

exports('getPlayerTheme', getPlayerTheme)
exports('setPlayerTheme', setPlayerTheme)

RegisterNUICallback('qbtheme:ready', function(_, cb)
    cb({ overrides = selectedColour, picker = pickerState() })
end)

RegisterNUICallback('qbtheme:set', function(payload, cb)
    local value = type(payload) == 'table' and payload.colour or nil
    local ok, message = setPlayerTheme(value)
    cb({ ok = ok, message = message, state = pickerState() })
end)

RegisterNUICallback('qbtheme:close', function(_, cb)
    cb({})
    closePicker()
end)

if ENABLED then
    local function addChatSuggestion()
        TriggerEvent('chat:addSuggestion', '/' .. COMMAND, 'Choose your personal server colour scheme.', {
            { name = 'colour', help = 'Optional #RRGGBB, or reset' },
        })
    end

    RegisterCommand(COMMAND, function(_, args)
        local value = type(args) == 'table' and args[1] or nil
        if not value then
            openPicker()
            return
        end

        local lowered = value:lower()
        if lowered == 'reset' or lowered == 'default' then value = 'reset' end
        local ok, message = setPlayerTheme(value)
        if not ok then
            TriggerEvent('chat:addMessage', { args = { 'Theme', message } })
        end
    end, false)

    addChatSuggestion()

    -- kora_theme normally starts before the chat resource, so repeat the
    -- suggestion when kora_chat becomes available instead of relying on startup
    -- order. kora_chat replaces the existing entry when it is already present.
    AddEventHandler('onClientResourceStart', function(resource)
        if resource == 'kora_chat' then addChatSuggestion() end
    end)
end

AddEventHandler('onClientResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    closePicker()
    if ENABLED then TriggerEvent('chat:removeSuggestion', '/' .. COMMAND) end
end)
