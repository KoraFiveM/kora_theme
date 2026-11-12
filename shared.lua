local COLOURS = type(KoraThemeFile) == 'table' and KoraThemeFile.colours or {}
local SHAPE = type(KoraThemeFile) == 'table' and KoraThemeFile.shape or {}
-- Same values as theme.js; "none" is a zero shadow so it stays valid inside comma lists.
local SHADOWS = ({
    none = { low = '0 0 #0000', floating = '0 0 #0000', modal = '0 0 #0000' },
    soft = { low = '0 2px 8px rgb(0 0 0 / 24%)', floating = '0 10px 28px rgb(0 0 0 / 40%)', modal = '0 20px 56px rgb(0 0 0 / 50%)' },
})[SHAPE.shadows] or { low = '0 4px 12px rgb(0 0 0 / 28%)', floating = '0 12px 32px rgb(0 0 0 / 42%)', modal = '0 24px 64px rgb(0 0 0 / 55%)' }

local warned = {}

local function warnOnce(key, message)
    if warned[key] then return end
    warned[key] = true
    print(('[kora_theme] %s'):format(message))
end

local function validHex(value)
    return type(value) == 'string' and value:match('^#%x%x%x%x%x%x$') ~= nil
end

local function round1(value)
    return math.floor(value * 10 + 0.5) / 10
end

-- Fixed precision, then trimmed: tostring() can expose float noise such as
-- 0.54999999999996 for 0.55, which theme.js would print as 0.55.
local function numberString(value)
    if value == math.floor(value) then return tostring(math.floor(value)) end
    local text = ('%.4f'):format(value):gsub('0+$', ''):gsub('%.$', '')
    return text
end

local function rgbFromHex(hex)
    return tonumber(hex:sub(2, 3), 16), tonumber(hex:sub(4, 5), 16), tonumber(hex:sub(6, 7), 16)
end

local function hslFromHex(hex)
    local red, green, blue = rgbFromHex(hex)
    local r, g, b = red / 255, green / 255, blue / 255
    local maxValue, minValue = math.max(r, g, b), math.min(r, g, b)
    local hue, saturation, lightness = 0, 0, (maxValue + minValue) / 2

    if maxValue ~= minValue then
        local delta = maxValue - minValue
        saturation = lightness > 0.5 and delta / (2 - maxValue - minValue) or delta / (maxValue + minValue)

        if maxValue == r then
            hue = (g - b) / delta + (g < b and 6 or 0)
        elseif maxValue == g then
            hue = (b - r) / delta + 2
        else
            hue = (r - g) / delta + 4
        end
        hue = hue / 6
    end

    return round1(hue * 360), round1(saturation * 100), round1(lightness * 100)
end

local function hslToken(hex, alpha, lightnessOffset)
    local h, s, l = hslFromHex(hex)
    if lightnessOffset then l = round1(math.max(0, math.min(100, l + lightnessOffset))) end
    local value = ('%s %s%% %s%%'):format(numberString(h), numberString(s), numberString(l))
    if alpha then value = ('%s / %s'):format(value, numberString(alpha)) end
    return value
end

local function relativeLuminance(hex)
    local red, green, blue
    if type(hex) == 'number' then red, green, blue = hex, hex, hex else red, green, blue = rgbFromHex(hex) end
    local function channel(value)
        value = value / 255
        return value <= 0.03928 and value / 12.92 or ((value + 0.055) / 1.055) ^ 2.4
    end
    return 0.2126 * channel(red) + 0.7152 * channel(green) + 0.0722 * channel(blue)
end

-- Fixed dark text grey (16/255) used for primary-foreground contrast.
local DARK_CHANNEL = 16
local function contrastToken(hex)
    local luminance = relativeLuminance(hex)
    local whiteContrast = 1.05 / (luminance + 0.05)
    local darkLuminance = relativeLuminance(DARK_CHANNEL)
    local darkContrast = (luminance + 0.05) / (darkLuminance + 0.05)
    return whiteContrast >= darkContrast and '0 0% 100%' or '0 0% 6.3%'
end

local function resolveColours(overrides)
    if type(overrides) == 'string' then overrides = { primary = overrides } end
    if type(overrides) ~= 'table' then overrides = {} end

    local colours = {}
    for key in pairs(COLOURS) do
        local value = overrides[key]
        if value ~= nil and not validHex(value) then
            warnOnce(('override:%s:%s'):format(key, tostring(value)), ('Theme override %q must be #RRGGBB; ignoring it.'):format(key))
            value = nil
        end
        colours[key] = value and value:upper() or COLOURS[key]
    end
    return colours
end

local function fontFile()
    return type(KoraThemeFile) == 'table' and type(KoraThemeFile.resolveFont) == 'function' and KoraThemeFile or nil
end

-- One slot's choice, by precedence: a /config custom family, the /config
-- dropdown (unless it is 'theme'), then theme.json. Returns the resolved font
-- (stack nil for "default") and where it came from.
local function chooseFont(slot, kind)
    local file = fontFile()
    local configured = type(KoraThemeConfig) == 'table' and type(KoraThemeConfig.fonts) == 'table' and KoraThemeConfig.fonts or {}
    local custom = type(configured.custom) == 'table' and configured.custom[slot] or nil
    if type(custom) == 'string' and custom:match('%S') then
        local font = file and file.resolveFont(custom, kind)
        if font then return font, 'config' end
        warnOnce(('font:%s:%s'):format(slot, custom), ('Custom %s font %q is not a plain font-family list; ignoring it.'):format(slot, custom))
    end
    local choice = configured[slot]
    if type(choice) == 'string' and choice ~= 'theme' then
        local font = file and file.resolveFont(choice, kind)
        if font then return font, 'config' end
        warnOnce(('font:%s:%s'):format(slot, choice), ('Configured %s font %q is unknown; ignoring it.'):format(slot, choice))
    end
    local fileValue = file and file.fonts and file.fonts[slot]
    if fileValue and fileValue ~= 'default' then
        local font = file.resolveFont(fileValue, kind)
        if font then return font, 'theme.json' end
    end
    return { id = 'default', label = 'Default' }, 'default'
end

---Resolved fonts per slot: { id, label, stack, source }. "default" uses the
---theme.css stack for body/mono; a default heading uses the body font.
local function getFonts()
    local defaults = fontFile() and KoraThemeFile.fontDefaults or {}
    local fonts = {}
    for _, slot in ipairs({ 'body', 'heading', 'mono' }) do
        local kind = slot == 'mono' and 'mono' or 'sans'
        local font, source = chooseFont(slot, kind)
        font.source = source
        if not font.stack then
            font.stack = slot == 'heading' and fonts.body.stack or defaults[kind]
        end
        fonts[slot] = font
    end
    return fonts
end

local function getTokens(overrides)
    local c = resolveColours(overrides)
    local fonts = getFonts()
    return {
        background = hslToken(c.background),
        foreground = hslToken(c.foreground),
        card = hslToken(c.surface),
        ['card-foreground'] = hslToken(c.foreground),
        popover = hslToken(c.surfacePopover),
        ['popover-foreground'] = hslToken(c.foreground),
        secondary = hslToken(c.surfaceRaised),
        ['secondary-foreground'] = hslToken(c.foreground),
        muted = hslToken(c.surfaceRaised),
        ['muted-foreground'] = hslToken(c.mutedForeground),
        accent = hslToken(c.surfaceHover),
        ['accent-foreground'] = hslToken(c.foreground),
        border = hslToken(c.border),
        ['border-strong'] = hslToken(c.borderStrong),
        input = hslToken(c.control),
        ['control-border'] = hslToken(c.control),
        ['control-border-hover'] = hslToken(c.controlHover),
        ['surface-raised'] = hslToken(c.surfaceRaised),
        ['surface-hover'] = hslToken(c.surfaceHover),
        hud = hslToken(c.surface, 0.72),
        ['modal-overlay'] = hslToken(c.background, 0.68),
        primary = hslToken(c.primary),
        ring = hslToken(c.primary),
        ['focus-ring'] = hslToken(c.primary, 0.55),
        selection = hslToken(c.primary, 0.35),
        ['brand-hover'] = hslToken(c.primary, nil, -5.1),
        ['brand-pressed'] = hslToken(c.primary, nil, -10.6),
        ['brand-soft'] = hslToken(c.primary, 0.14),
        ['brand-border'] = hslToken(c.primary, 0.45),
        ['primary-foreground'] = contrastToken(c.primary),
        success = hslToken(c.success),
        ['success-soft'] = hslToken(c.success, 0.14),
        ['success-border'] = hslToken(c.success, 0.45),
        ['success-foreground'] = contrastToken(c.success),
        warning = hslToken(c.warning),
        ['warning-soft'] = hslToken(c.warning, 0.14),
        ['warning-border'] = hslToken(c.warning, 0.45),
        ['warning-foreground'] = contrastToken(c.warning),
        destructive = hslToken(c.danger),
        danger = hslToken(c.danger),
        ['destructive-soft'] = hslToken(c.danger, 0.14),
        ['destructive-border'] = hslToken(c.danger, 0.45),
        ['destructive-foreground'] = contrastToken(c.danger),
        info = hslToken(c.info),
        ['info-soft'] = hslToken(c.info, 0.14),
        ['info-border'] = hslToken(c.info, 0.45),
        ['info-foreground'] = contrastToken(c.info),
        armour = hslToken(c.armour),
        surface = hslToken(c.surface, 0.97),
        ['surface-panel'] = hslToken(c.surfaceRaised, 0.98),
        ['secondary-text'] = hslToken(c.info),
        ['font-sans'] = fonts.body.stack,
        ['font-heading'] = fonts.heading.stack,
        ['font-mono'] = fonts.mono.stack,
        space = '0.25rem',
        ['space-1'] = '0.25rem',
        ['space-2'] = '0.5rem',
        ['space-3'] = '0.75rem',
        ['space-4'] = '1rem',
        ['space-6'] = '1.5rem',
        ['radius-sm'] = SHAPE.radius and ('%dpx'):format(math.floor(SHAPE.radius * 0.75 + 0.5)) or '0.375rem',
        radius = SHAPE.radius and ('%dpx'):format(SHAPE.radius) or '0.625rem',
        ['radius-lg'] = SHAPE.radius and ('%dpx'):format(math.floor(SHAPE.radius * 1.25 + 0.5)) or '0.8125rem',
        ['radius-full'] = '9999px',
        ['shadow-low'] = SHADOWS.low,
        ['shadow-floating'] = SHADOWS.floating,
        ['shadow-modal'] = SHADOWS.modal,
        ['duration-fast'] = '120ms',
        ['duration-popover'] = '160ms',
        ['duration-dialog'] = '180ms',
        ['ease-entry'] = 'cubic-bezier(0.16, 1, 0.3, 1)',
    }
end

local function getPrimaryColor()
    return COLOURS.primary
end

---Resolved palette as #RRGGBB strings keyed like theme.json's "colors" (primary, foreground,
---background, ...). Accepts the same overrides as getTokens; invalid overrides are ignored.
local function getColours(overrides)
    return resolveColours(overrides)
end

exports('getTokens', getTokens)
exports('getColours', getColours)
exports('getFonts', getFonts)
exports('getPrimaryColor', getPrimaryColor)
