local String = require("izelnakri.utils.string")
local uv = vim.uv

local VIM_FS_METHODS = {
  "dir", -- Returns an iterator<[{ name, type }]> on path
  "find", -- fun(basename, fullpath), { limit = , stop = "", upward = true, type =, path = } => string[](normalized)
  "root", -- very interesting? check for package.json: bufnr|string , string | string[], fun(name, path) -> goes upwards? . NOTE: EXPECTS ABSOLUTE PATH!, seonc param not important NOT sure if these are async or not. Just proxy them for now
}

-- NOTE: Should I implement is_directory(?)
--  nio.fn.isdirectory(path) == 1

FS = {}

for method in pairs(vim.uv) do
  if String.starts_with(method, "fs_") then
    if method == "fs_lchown" then
      FS.lchown = require("izelnakri.utils.fs.lchown")
    elseif method == "fs_readdir" then
      FS.readdir = require("izelnakri.utils.fs.readdir")
    elseif method == "fs_mkdir" then
      FS.mkdir = require("izelnakri.utils.fs.mkdir")
    else
      FS[String.split(method, "fs_")[2]] = vim.uv[method]
    end
  end
end

for _, method in ipairs(VIM_FS_METHODS) do
  if method == "dir" then
    -- Shows all directory and files, it is not recursive by default
    ---@param path string Relative or absolute path
    ---@param opts { depth: number | nil, skip: fun(dir_name: string): boolean } opts.skip is only possible for the directory_names.
    ---@return Iter
    FS.dir = function(path, opts)
      return vim.iter(vim.fs.dir(path, opts))
    end
  else
    FS[method] = vim.fs[method]
  end
end

FS.walk = FS.find
FS.mv = FS.rename

FS.appendfile = require("izelnakri.utils.fs.appendfile")
FS.cp = require("izelnakri.utils.fs.cp")
FS.readfile = require("izelnakri.utils.fs.readfile")
FS.rm = require("izelnakri.utils.fs.rm")
FS.watch = require("izelnakri.utils.fs.watch")
FS.writefile = require("izelnakri.utils.fs.writefile")

return FS
