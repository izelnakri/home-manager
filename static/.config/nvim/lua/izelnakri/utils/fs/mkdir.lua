-- local Callback = require("callback")
local List = require("izelnakri.utils.list")
local Path = require("izelnakri.utils.path")
local uv = vim.uv

---@param path string
---@param options? { recursive?: boolean, mode?: number }
---@param callback? fun(err?: string, success?: boolean)
return function(path, options, callback)
  if type(options) == "function" then
    callback = options
    options = {}
  end

  options = options or {}
  local mode = options.mode or 493 -- default to 0755

  local mkdir = function(dir_path, cb)
    if cb then
      return uv.fs_mkdir(dir_path, mode, cb)
    else
      local result, err = uv.fs_mkdir(dir_path, mode)
      if not result then
        return false, error(err or "Failed to create directory")
      end

      return true
    end
  end

  local function check_exists(target_path, cb)
    if cb then
      return uv.fs_stat(target_path, function(err, stat)
        if err or not stat then
          return cb(false, err)
        elseif stat.type == "file" then
          return cb(false, "EEXIST: file already exists: " .. target_path)
        end

        cb(true, "EEXIST: folder already exists: " .. target_path) -- directory exists
      end)
    else
      local stat, err = uv.fs_stat(target_path)
      if not stat then
        return false, err
      elseif stat.type == "file" then
        return false, error("EEXIST: file already exists: " .. target_path)
      end

      return true
    end
  end

  if options.recursive then
    local folder_names = Path.split(path)

    if callback then
      return Callback.reduce_right(folder_names, function(directories_to_create, _, next, index)
        local target_path = Path.join(List.slice(folder_names, 1, index))

        check_exists(target_path, function(err)
          if not err then
            List.unshift(directories_to_create, target_path)
          end

          next(nil, directories_to_create)
        end)
      end, {}, function(_, directories_to_create)
        return Callback.each_series(directories_to_create, mkdir, callback)
      end)
    else
      local directories_to_create = List.reduce_right(folder_names, function(directories_to_create, _, index)
        local target_path = Path.join(List.slice(folder_names, 1, index))
        if not check_exists(target_path) then
          List.unshift(directories_to_create, target_path)
        end
        return directories_to_create
      end, {})

      return List.reduce(directories_to_create, function(result, directory_path)
        return mkdir(directory_path)
      end, false)
    end
  elseif callback then
    return check_exists(path, function(exists, err)
      if exists then
        return callback(err, false)
      end

      return mkdir(path, callback)
    end)
  end

  local it_exists, err = check_exists(path)
  if it_exists then
    return false, err or error("EEXIST: folder already exists: " .. path)
  end

  return mkdir(path)
end
