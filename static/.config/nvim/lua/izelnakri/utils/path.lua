-- TODO: Add descriptions
local List = require("izelnakri.utils.list")
local String = require("izelnakri.utils.string")

Path = {}

---Returns an absolute path of a relative path provided, using optionally the second argument as cwd base
---@param path string
---@param cwd? string
---@return string
function Path.absname(path, cwd)
  path = Path.normalize(path)
  if String.starts_with(path, "/") then
    cwd = nil
  else
    cwd = (type(cwd) == "string" and #cwd > 0 and Path.normalize(cwd)) or vim.uv.cwd()
  end

  local result = Path.normalize(Path.join(cwd, path))
  if not String.starts_with(result, "/") then
    return "/" .. result
  end

  return result
end

Path.basename = vim.fs.basename
Path.dirname = vim.fs.dirname
Path.joinpath = vim.fs.joinpath
Path.normalize = vim.fs.normalize

---Joins directory paths or strings to create a path string
---@param ... string | string[]
---@return string
function Path.join(...)
  return vim.fs.joinpath(unpack(List.flatten({ ... })))
end

---Returns an iterator of every parent directory
---@param ... string
---@return Iter
function Path.parents(...)
  return vim.iter(vim.fs.parents(...))
end

---Returns the extension name of a provided file path
---@param path string
---@return string
function Path.extname(path)
  -- NOTE: this has to be "lua" etc
  local basename = Path.basename(path)
  local extension_start_index = String.last_index_of(basename, ".")
  if extension_start_index then
    return String.slice(basename, extension_start_index + 1, #basename + 1)
  end

  return ""
end

---Returns the file name of a provided file path
---@param path string
---@return string
function Path.filename(path)
  if String.ends_with(path, "/") then
    return ""
  end

  local basename = Path.basename(path)
  local extension_start_index = String.last_index_of(basename, ".")
  if not extension_start_index then
    return basename
  end

  return String.slice(basename, 1, extension_start_index)
end

---Returns whether the provided path is an absolute path or not
---@param path string
---@return boolean
function Path.is_absolute(path)
  return String.starts_with(path, "/") -- We do not check windows currently
end

-- ---Returns whether the provided path is an absolute path or not
-- ---@param from string
-- ---@param to string
-- ---@return string
-- function Path.relative(from, to)
--   -- TODO: Implement and write tests
-- end

---Turns a path string into a list of strings
---@param path string
---@return string[]
function Path.split(path)
  local result = String.split(path, "/")
  if result[1] == "" then
    result[1] = "/"
  end

  return result
end

return Path
