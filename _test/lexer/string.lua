return function()
  local _2lex = {
    -- quotes & double quotes
    "\'abc\'",
    "\"abc\"",
    -- escape sequences
    "\"\\a\"",
    "\"\\b\"",
    "\"\\f\"",
    "\"\\n\"",
    "\"\\r\"",
    "\"\\t\"",
    "\"\\v\"",
    "\"\\7\"",
    "\"\\12\"",
    "\"\\255\"",
    "\"\\\\\"",
    "\"\\\\n\"",
    "\"\\\\r\""
  }

  local _2err = {
    { "\'",        "Unfinished string" },
    { "\"",        "Unfinished string" },
    { "\"\\x\"",   "Invalid escape sequence" },
    { "\"\\256\"", "Invalid escape sequence" }
  }

  for _, data in ipairs(_2lex) do
    local token = lexer(data)[1]
    local _start, _end = table.unpack(token.range)
    lu.assertEquals(token.type, 'TK_STRING')
    lu.assertEquals(token.data, data)
    lu.assertEquals(string.sub(data, _start, _end), token.data)
  end

  for _, data in ipairs(_2err) do
    local src, err = table.unpack(data)
    lu.assertErrorMsgContains(err, function()
      lexer(src)
    end)
  end
end
