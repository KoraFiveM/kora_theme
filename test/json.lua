-- Minimal json.decode so the plain-Lua tests behave like FiveM's json global.
local function decode(text)
    local pos = 1
    local function skip() pos = text:find('[^ \t\r\n]', pos) or #text + 1 end
    local value
    local function str()
        local close = text:find('"', pos + 1, true)
        local out = text:sub(pos + 1, close - 1)
        pos = close + 1
        return out
    end
    function value()
        skip()
        local c = text:sub(pos, pos)
        if c == '{' then
            local out = {}
            pos = pos + 1; skip()
            if text:sub(pos, pos) == '}' then pos = pos + 1 return out end
            repeat
                skip(); local key = str(); skip()
                assert(text:sub(pos, pos) == ':', 'expected colon'); pos = pos + 1
                out[key] = value(); skip()
                local d = text:sub(pos, pos); pos = pos + 1
            until d == '}'
            return out
        elseif c == '[' then
            local out = {}
            pos = pos + 1; skip()
            if text:sub(pos, pos) == ']' then pos = pos + 1 return out end
            repeat
                out[#out + 1] = value(); skip()
                local d = text:sub(pos, pos); pos = pos + 1
            until d == ']'
            return out
        elseif c == '"' then return str()
        else
            local literal = text:match('^[%w%.%-]+', pos)
            assert(literal, 'invalid json at ' .. pos)
            pos = pos + #literal
            return tonumber(literal) or (literal == 'true') or nil
        end
    end
    local result = value(); skip()
    assert(pos > #text, 'trailing json')
    return result
end

_G.json = { decode = decode }
