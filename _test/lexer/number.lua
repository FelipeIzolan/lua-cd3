return function()
  local _2lex = {
    -- whole number
    '5',
    '10',
    -- fractional number
    '.5',
    '.75',
    '5.',
    '10.',
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
    '0XF',
    -- hex radix
    '0xf.',
    '0xf.a',
    -- hex binary exponential notation
    '0xfp1',
    '0xfp+1',
    '0xfp-1',
    '0xfP1',
    '0xfP+1',
    '0xfP-1',
    '0xf.ap1',
    '0xf.ap+1',
    '0xf.ap-1',
    '0xf.aP1',
    '0xf.aP+1',
    '0xf.aP-1',
  }

  local _2err = {
    { "3E",   "Invalid exponential notation" },
    { "0XfP", "Invalid exponential notation" }
  }

  for _, data in ipairs(_2lex) do
    local token = lexer(data)[1]
    local _start, _end = table.unpack(token.range)
    lu.assertEquals(token.type, 'TK_NUMBER')
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
