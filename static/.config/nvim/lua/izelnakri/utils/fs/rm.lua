local Path = require("izelnakri.utils.path")
local readdir = require("izelnakri.utils.fs.readdir")
local uv = vim.uv

local function check_exists(target_path, cb)
  if cb then
    return uv.fs_stat(target_path, function(err, stat)
      if err or not stat then
        return cb(false, err or "Path does not exist")
      end
      cb(true, stat.type)
    end)
  else
    local stat, err = uv.fs_stat(target_path)
    if not stat then
      return false, err or "Path does not exist"
    end
    return true, stat.type
  end
end

local function remove_file(file_path, cb)
  if cb then
    return uv.fs_unlink(file_path, function(err)
      if err then
        cb("Failed to remove file: " .. err, false)
      else
        cb(nil, true)
      end
    end)
  else
    local result, err = uv.fs_unlink(file_path)
    if not result then
      return false, "Failed to remove file: " .. (err or "unknown error")
    end
    return true
  end
end

local function remove_dir(dir_path, cb)
  if cb then
    return uv.fs_rmdir(dir_path, function(err)
      if err then
        cb("Failed to remove directory: " .. err, false)
      else
        cb(nil, true)
      end
    end)
  else
    local result, err = uv.fs_rmdir(dir_path)
    if not result then
      return false, "Failed to remove directory: " .. (err or "unknown error")
    end
    return true
  end
end

local function delete_dir_async_recursive(dir_path, cb)
  readdir(dir_path, { recursive = false }, function(err, entries)
    if err then
      return cb("Failed to read directory: " .. err, false)
    end

    -- Filter out '.' and '..' entries to prevent accidental deletion of current and parent directories
    local filtered_entries = {}
    for _, entry in ipairs(entries) do
      local basename = Path.basename(entry.name)
      if basename ~= "." and basename ~= ".." then
        table.insert(filtered_entries, entry)
      end
    end

    if #filtered_entries == 0 then
      return remove_dir(dir_path, cb)
    end

    Callback.each_series(filtered_entries, function(entry, next_cb)
      local full_path = entry.name -- Assuming entry.name is the full path

      if entry.type == "directory" then
        delete_dir_async_recursive(full_path, function(err_)
          if err_ then
            return next_cb(err_)
          end
          next_cb()
        end)
      else
        remove_file(full_path, function(err_)
          if err_ then
            return next_cb(err_)
          end
          next_cb()
        end)
      end
    end, function(err_)
      if err_ then
        return cb(err_, false)
      end

      remove_dir(dir_path, cb)
    end)
  end)
end

local function delete_dir_sync_recursive(dir_path)
  local scan = uv.fs_scandir(dir_path)
  if not scan then
    return false, "Failed to open directory: " .. dir_path
  end

  while true do
    local name, type_ = uv.fs_scandir_next(scan)
    if not name then
      break
    end

    if name ~= "." and name ~= ".." then
      local full_path = Path.join(dir_path, name)
      local exists_inner, type_inner = check_exists(full_path)
      if not exists_inner then
        return false, "Path does not exist: " .. full_path
      end

      if type_inner == "directory" then
        local success, err = delete_dir_sync_recursive(full_path)
        if not success then
          return false, err
        end
      else
        local success, err = remove_file(full_path)
        if not success then
          return false, err
        end
      end
    end
  end

  return remove_dir(dir_path)
end

---@param path string
---@param options? { recursive?: boolean }
---@param callback? fun(err?: string, success?: boolean)
---@return boolean?, string?
return function(path, options, callback)
  if type(options) == "function" then
    callback = options
    options = {}
  end

  options = options or {}
  local recursive = options.recursive or false

  if callback then
    check_exists(path, function(exists, type_)
      if not exists then
        return callback("Path does not exist: " .. path, false)
      end

      if type_ == "file" then
        return remove_file(path, callback)
      elseif type_ == "directory" then
        if recursive then
          return delete_dir_async_recursive(path, callback)
        else
          return remove_dir(path, callback)
        end
      else
        return callback("Unsupported file type: " .. type_, false)
      end
    end)
  else
    local exists, type_or_err = check_exists(path)
    if not exists then
      return false, type_or_err or "Path does not exist: " .. path
    end

    if type_or_err == "file" then
      return remove_file(path)
    elseif type_or_err == "directory" then
      if recursive then
        return delete_dir_sync_recursive(path)
      else
        -- Attempt to remove an empty directory
        return remove_dir(path)
      end
    else
      return false, "Unsupported file type: " .. tostring(type_or_err)
    end
  end
end
