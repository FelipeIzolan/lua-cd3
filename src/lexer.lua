return function(src)
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

  local pos = 1
  local tokens = {}

  local function push(type, data)
    local l = #data
    local e = pos + l
    tokens[#tokens + 1] = {
      type = type,
      data = data,
      range = { pos, (l == 1 and e - 1 or e) }
    }
    pos = e
  end

  -- type = 1 - Unfinished long string
  -- type = 2 - Unfinished string
  -- type = 3 - Unexpected Token
  local function throw(type, expected)
    local m = { 
      "Unfinished long string; expected %s",
      "Unfinished string; expected %s"
    }
    error(string.format(m[type], expected))
  end

  local function read_string(del)
    local i = pos
    ::continue::
    local s, e, m = string.find(src, '([\n\r\\\"\'])', i)
    if s then
      if m == '\n' or m == '\r' then
        throw(2, del)
      end
      if m == '\\' then
      end
      i = s
      goto continue
    end
    throw(2, del)
  end

  local function read_long_string(sep)
    sep = ']' .. sep .. ']'
    local s, e, m = string.find(src, sep, pos)
    if s then
      return string.sub(src, pos, e)
    else
      throw(1, sep)
    end
  end

  -- CheatSheet - Lua Pattern
  -- https://cheatography.com/ambigious/cheat-sheets/lua-string-patterns/
  -- https://github.com/lua/lua/blob/3fb7a77731e6140674a6b13b73979256bfb95ce3/lstrlib.c#L420

  ::continue::
  -- whitespace (' ', \n, \r & \t)
  -- https://en.cppreference.com/w/c/string/byte/isspace
  local s, e, m = string.find(src, "^(%s*)", pos)
  if m and m ~= '' then
    push('TK_SPACE', m)
    goto continue
  end
  -- identifier & keyword
  local s, e, m = string.find(src, "^([_%a][_%w]*)", pos)
  if s then
    push(keyword[m] and "TK_KEYWORD" or "TK_IDENTIFIER", m)
    goto continue
  end
  -- numeral (int, float, exponential notation & hex)
  local s, e, m = string.find(src, "^(%.?)%d", pos)
  if s then
    local i = pos
    if m ~= '' then i = i + 1 end
    local s, e, m = string.find(src, "^%d*" .. (m ~= '.' and '%.?%d*' or '') .. "([eE]?)", i)
    i = e
    -- exponential notation
    if m ~= '' then
      local s, e, m = string.find(src, "^[%+%-]%d+", i)
      i = e
    end
    -- hex
    local s, e, m = string.find(src, "^0x%x+", i)
    if s then
      i = e
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
      push('TK_STRING', read_string());
      goto continue
    end
  end

  return tokens
end
