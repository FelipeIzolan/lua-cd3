lu = require '_test.luaunit'
lexer = require 'src.lexer'

TestLexer = {
  TestNumber = require '_test.lexer.number',
  TestString = require '_test.lexer.string'
}
TestParser = {}
TestMinifier = {}

os.exit(lu.LuaUnit.run())
