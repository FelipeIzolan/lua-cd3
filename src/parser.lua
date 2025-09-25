local lexer = require('src.lexer')

return function(src)
  local tokens = lexer(src)
  local root = {}
end
