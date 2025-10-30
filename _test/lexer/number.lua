return function()
  local _2lex = {
    -- whole number
    '5',
    '10',
    -- fractional number
    '.5',
    '.75',
    '3.5',
    '3.15',
    -- exponential notation
    '3e1',
    '3e+1',
    '3e-1',
    '3E1',
    '3E+1',
    '3E-1',
    '3.5e1',
    '3.5e+1',
    '3.5e-1',
    '3.5E1',
    '3.5E+1',
    '3.5E-1',
    -- hex
    '0xf',
    '0x5f'
  }

  for _, data in ipairs(_2lex) do
    local token = lexer(data)[1]
    local _start, _end = table.unpack(token.range)
    lu.assertEquals(token.type, 'TK_NUMBER')
    lu.assertEquals(token.data, data)
    lu.assertEquals(string.sub(data, _start, _end), token.data)
  end
end
