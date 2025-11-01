return function()
  local _2lex = {
    "and",
    "break",
    "do",
    "else",
    "elseif",
    "end",
    "false",
    "for",
    "function",
    "goto",
    "if",
    "in",
    "local",
    "nil",
    "not",
    "or",
    "repeat",
    "return",
    "then",
    "true",
    "until",
    "while",
  }

  for _, data in ipairs(_2lex) do
    local token = lexer(data)[1]
    local _start, _end = table.unpack(token.range)
    lu.assertEquals(token.type, 'TK_KEYWORD')
    lu.assertEquals(token.data, data)
    lu.assertEquals(string.sub(data, _start, _end), token.data)
  end
end
