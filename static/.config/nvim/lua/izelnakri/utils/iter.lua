Iter = {}

local ITER_LIST_SPECIMEN = vim.iter({ "a" })
local ITER_OBJECT_SPECIMEN = vim.iter({ a = true })
local METHODS = {
  "all",
  "any",
  "each",
  "enumerate",
  "filter", -- vim.iter().filter invalid for list iter but valid for object iter
  "find",
  "flatten",
  "fold",
  "join",
  "last",
  "map",
  "next",
  "nth",
  "peek",
  "pop",
  "rev",
  "rfind",
  "rpeek",
  "rskip",
  "skip",
  "slice",
  "take",
  "totable",
}

for _, method in pairs(METHODS) do
  Iter[method] = function(...)
    local arguments = { ... }
    local iter_reference = arguments[1]

    if not Iter.is_iter(iter_reference) then
      return error(
        "Iter." .. method .. " only accepts vim.iter() values, you've provided: " .. tostring(iter_reference)
      )
    end

    return iter_reference[method](...)
  end
end

Iter.is_iter = function(value)
  local target_value_metatable = vim.inspect(getmetatable(value))

  return (vim.inspect(getmetatable(ITER_LIST_SPECIMEN)) == target_value_metatable)
    or (vim.inspect(getmetatable(ITER_OBJECT_SPECIMEN)) == target_value_metatable)
end

Iter.every = Iter.all
Iter.some = Iter.any

function Iter:new(value)
  return vim.iter(value)
end

return Iter
