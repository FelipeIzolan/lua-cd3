local parser = require('src.parser')

return function(src)
  local ast = parser(src)
end
