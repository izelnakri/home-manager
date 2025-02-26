Function = {}

function Function.pipe(...)
  local arguments = { ... }
  if #arguments >= 2 then
    local value = table.remove(arguments, 1)
    local func = table.remove(arguments, 1)

    return Function.pipe(func(value), unpack(arguments))
  elseif #arguments == 2 then
    if type(arguments[2]) ~= "function" then
      error("Function.pipe(val, ..funcs): one of the provided functions to pipe is not a function!")
    end

    return arguments[2](arguments[1])
  end

  return arguments[1]
end

return Function
