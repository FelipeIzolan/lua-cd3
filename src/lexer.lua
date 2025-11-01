local keyword = {
  ["and"] = true,
  ["break"] = true,
  ["do"] = true,
  ["else"] = true,
  ["elseif"] = true,
  ["end"] = true,
  ["false"] = true,
  ["for"] = true,
  ["function"] = true,
  ["goto"] = true,
  ["if"] = true,
  ["in"] = true,
  ["local"] = true,
  ["nil"] = true,
  ["not"] = true,
  ["or"] = true,
  ["repeat"] = true,
  ["return"] = true,
  ["then"] = true,
  ["true"] = true,
  ["until"] = true,
  ["while"] = true
}

local function throw(index, payload)
  local err = {
    "Unfinished long string; expected: %s",
    "Unfinished string; expected: %s",
    "Invalid escape sequence; '%s'",
    "Invalid exponential notation; %s"
  }
  error(string.format(err[index], payload))
end

return function(src)
  local pos = 1
  local tokens = {}

  local function push(type, data)
    local l = #data
    local e = pos + l
    tokens[#tokens + 1] = {
      type = type,
      data = data,
      range = { pos, e - 1 }
    }
    pos = e
  end

  local function read_string(del)
    local i = pos + 1
    ::continue::
    local s, e, m = string.find(src, '([\n\r\"\'\\])', i)
    if s then
      i = s
      if m == '\n' or m == '\r' then
        throw(2, '\\n or \\r | ' .. del)
      end
      -- possible end (' or ")
      if m == del then
        return string.sub(src, pos, i)
      end
      -- escape sequence (\b, \255, ...)
      -- https://en.wikipedia.org/wiki/Escape_sequences_in_C
      if m == '\\' then
        local s, e, m = string.find(src, '^[abfnrtv\\\'\"\n\r]', i + 1)
        if s then
          i = s
          goto continue
        end
        local s, e, m = string.find(src, '^(%d%d?%d?)', i + 1)
        if s then
          if tonumber(m) > 255 then
            throw(3, '\\' .. m)
          end
          i = e
          goto continue
        end
        throw(3, '\\' .. string.sub(src, i, i))
      end
      goto continue
    end
    throw(2, del)
  end

  local function read_long_string(sep)
    sep = ']' .. sep .. ']'
    local s, e = string.find(src, sep, pos)
    if s then
      return string.sub(src, pos, e)
    else
      throw(2, sep)
    end
  end

  local function exponential_notation(i)
    local s, e, m = string.find(src, "^[%+%-]?%d+", i)
    if not s then
      throw(4, string.sub(src, pos, i))
    end
    return e
  end

  -- Lua Pattern Matching
  -- https://gist.github.com/spr2-dev/46ca9f4a6f933fa266bccd87fd15d09a
  -- https://github.com/lua/lua/blob/3fb7a77731e6140674a6b13b73979256bfb95ce3/lstrlib.c#L420

  ::continue::
  -- whitespace (' ', \n, \r & \t)
  -- https://en.cppreference.com/w/c/string/byte/isspace
  local s, e, m = string.find(src, "^(%s*)", pos)
  if m and m ~= '' then
    push('TK_SPACE', m)
    goto continue
  end
  -- numeral (int, float, exponential notation & hex)
  local s, e, m = string.find(src, "^(%.?)%d", pos)
  if s then
    local i = pos
    local s, e, m = string.find(src, "^%d+" .. (m ~= '.' and "%.?%d*([eE]?)" or "([eE]?)"), m ~= '' and i + 1 or i) -- any way to improve this?
    i = e
    -- exponential notation
    if m ~= '' then
      i = exponential_notation(i + 1)
    end
    -- hex
    local s, e, m = string.find(src, "^0[xX]%x+%.?%x*([pP]?)", i)
    if s then
      i = e
      -- binary exponentional notation
      if m ~= '' then
        i = exponential_notation(i + 1)
      end
    end
    push('TK_NUMBER', string.sub(src, pos, i))
    goto continue
  end
  -- punctuation
  -- https://en.cppreference.com/w/c/string/byte/ispunct
  local s, e = string.match(src, "^(%p)(%p?)", pos)
  if s then
    -- comment
    if s == '-' and e == '-' then
      local s, e, m = string.find(src, "^--%[(=*)%[", pos)
      if s then -- block comment
        push('TK_LCOMMENT', read_long_string(m))
      else      -- comment
        local s, e, m = string.find(src, '\n', pos)
        push('TK_COMMENT', string.sub(src, pos, e and e or #src))
      end
      goto continue
    end
    -- long string
    if s == '[' and (e == '=' or e == '[') then
      local s, e, m = string.find(src, "^%[(=*)%[", pos)
      push('TK_LSTRING', read_long_string(m))
      goto continue
    end
    -- string
    if s == '\"' or s == '\'' then
      push('TK_STRING', read_string(s));
      goto continue
    end
    -- dots (.|..|..)
    if s == '.' then
      local s = string.match(src, "^(%.%.?%.?)", pos)
      push('TK_OP', s)
      goto continue
    end
    -- ==, ~=, >=, <=
    if e == '=' and (s == '=' or s == '~' or s == '>' or s == '<') then
      push('TK_OP', s .. e)
      goto continue
    end
    -- floor division (//)
    if s == '/' and e == '/' then
      push('TK_OP', s .. e)
      goto continue
    end
    -- etc...
    push('TK_OP', s)
    goto continue
  end
  -- identifier & keyword
  local s, e, m = string.find(src, "^([_%a][_%w]*)", pos)
  if s then
    push(keyword[m] and "TK_KEYWORD" or "TK_IDENTIFIER", m)
    goto continue
  end
  return tokens
end
