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

local function create_dir(dir_path, cb)
  if cb then
    return uv.fs_mkdir(dir_path, 493, function(err)
      if err then
        cb("Failed to create directory: " .. dir_path .. " - " .. err, false)
      else
        cb(nil, true)
      end
    end)
  else
    local result, err = uv.fs_mkdir(dir_path, 493) -- 0755 permissions
    if not result then
      return false, "Failed to create directory: " .. dir_path .. " - " .. (err or "unknown error")
    end
    return true
  end
end

local function handle_file_open(src_file, dest_file, options, cb)
  uv.fs_stat(src_file, function(err, src_stat)
    if err then
      return cb(err, false) -- handle error if stat fails
    end

    uv.fs_open(src_file, "r", 438, function(err, src_fd)
      if err then
        return cb("Failed to open source file: " .. src_file .. " - " .. err, false)
      end

      local flags = options.force and "w" or "wx"
      uv.fs_open(dest_file, flags, options.mode or 438, function(err, dest_fd)
        if err then
          uv.fs_close(src_fd)

          return cb("Failed to open destination file: " .. dest_file .. " - " .. err, false)
        end

        cb(nil, src_fd, dest_fd, src_stat)
      end)
    end)
  end)
end

local function copy_file_async(src_file, dest_file, cb, options)
  check_exists(dest_file, function(exists, type_)
    if exists then
      if options.error_on_exist then
        return cb("Destination exists: " .. dest_file, false)
      elseif not options.force then
        return cb("Destination exists and force is false: " .. dest_file, false)
      end
    end

    handle_file_open(src_file, dest_file, options, function(err, src_fd, dest_fd, src_stat)
      if err then
        return cb(err, false)
      end

      local buffer_size = 4096

      local function read_write_loop()
        uv.fs_read(src_fd, buffer_size, -1, function(read_err, data)
          if read_err then
            uv.fs_close(src_fd)
            uv.fs_close(dest_fd)
            return cb("Failed to read from source: " .. src_file .. " - " .. read_err, false)
          elseif not data or #data == 0 then
            uv.fs_close(src_fd)
            if options.preserve_timestamps then
              return uv.fs_futime(dest_fd, src_stat.atime.sec, src_stat.mtime.sec, function(err)
                uv.fs_close(dest_fd)

                if err then
                  return cb(err, false) -- handle futime error
                end

                cb(nil, true) -- copy complete
              end)
            end

            uv.fs_close(dest_fd)
            return cb(nil, true)
          end

          return uv.fs_write(dest_fd, data, -1, function(write_err)
            if write_err then
              uv.fs_close(src_fd)
              uv.fs_close(dest_fd)
              return cb("Failed to write to destination: " .. dest_file .. " - " .. write_err, false)
            end
            read_write_loop()
          end)
        end)
      end

      read_write_loop()
    end)
  end)
end

local function copy_file_sync(src_file, dest_file, options)
  local exists, type_or_err = check_exists(dest_file)
  if exists then
    if options.error_on_exist then
      return false, "Destination exists: " .. dest_file
    elseif not options.force then
      return false, "Destination exists and force is false: " .. dest_file
    end
  end

  local src_fd, err = uv.fs_open(src_file, "r", 438) -- 0666 permissions
  if not src_fd then
    return false, "Failed to open source file: " .. src_file .. " - " .. (err or "unknown error")
  end

  local flags = options.force and "w" or "wx" -- "wx" fails if dest exists
  local dest_fd, err = uv.fs_open(dest_file, flags, options.mode or 438)
  if not dest_fd then
    uv.fs_close(src_fd)
    if err:match("EEXIST") then
      return false, "Destination file already exists: " .. dest_file
    else
      return false, "Failed to open destination file: " .. dest_file .. " - " .. (err or "unknown error")
    end
  end

  local buffer_size = 4096

  while true do
    local data, err = uv.fs_read(src_fd, buffer_size, -1)
    if not data then
      uv.fs_close(src_fd)
      uv.fs_close(dest_fd)
      return false, "Failed to read from source file: " .. src_file .. " - " .. (err or "unknown error")
    end

    if #data == 0 then
      -- EOF reached
      break
    end

    local bytes_written, err = uv.fs_write(dest_fd, data, -1)
    if not bytes_written then
      uv.fs_close(src_fd)
      uv.fs_close(dest_fd)
      return false, "Failed to write to destination file: " .. dest_file .. " - " .. (err or "unknown error")
    end
  end

  uv.fs_close(src_fd)
  uv.fs_close(dest_fd)

  if options.preserve_timestamps then
    local stat_src, err_stat = uv.fs_stat(src_file)
    if stat_src then
      uv.fs_utime(dest_file, stat_src.atime.sec, stat_src.mtime.sec)
    end
  end

  return true
end

local function copy_dir_async_recursive(src_dir, dest_dir, cb, options)
  create_dir(dest_dir, function(err, success)
    if err then
      return cb(err, false)
    end

    readdir(src_dir, { recursive = false }, function(err, entries)
      if err then
        return cb("Failed to read directory: " .. src_dir .. " - " .. err, false)
      end

      local filtered_entries = {}
      for _, entry in ipairs(entries) do
        if options.filter(entry.type, entry.name) then
          table.insert(filtered_entries, entry)
        end
      end

      if #filtered_entries == 0 then
        return cb(nil, true)
      end

      Callback.each_series(filtered_entries, function(entry, next_cb)
        local src_path = entry.name -- Full path
        local dest_path = Path.join(dest_dir, Path.basename(src_path))

        if entry.type == "directory" then
          copy_dir_async_recursive(src_path, dest_path, function(err_)
            if err_ then
              return next_cb(err_)
            end
            next_cb()
          end, options)
        else
          copy_file_async(src_path, dest_path, function(err_)
            if err_ then
              return next_cb(err_)
            end
            next_cb()
          end, options)
        end
      end, function(err_)
        if err_ then
          return cb(err_, false)
        end

        cb(nil, true)
      end)
    end)
  end)
end

local function copy_dir_sync_recursive(src_dir, dest_dir, options)
  local success, err = create_dir(dest_dir)
  if not success then
    return false, err
  end

  local scan = uv.fs_scandir(src_dir)
  if not scan then
    return false, "Failed to open directory: " .. src_dir
  end

  while true do
    local name, type_ = uv.fs_scandir_next(scan)
    if not name then
      break
    end

    local src_path = Path.join(src_dir, name)
    local dest_path = Path.join(dest_dir, name)

    if options.filter(type_, src_path) then
      if type_ == "directory" then
        if not options.recursive then
          return false, "Cannot copy directory without recursive option"
        end
        local success, err = copy_dir_sync_recursive(src_path, dest_path, options)
        if not success then
          return false, err
        end
      else
        local success, err = copy_file_sync(src_path, dest_path, options)
        if not success then
          return false, err
        end
      end
    end
  end

  return true
end

---@param src string Source path (file, directory, or symlink)
---@param dest string Destination path
---@param options? {
---@   recursive?: boolean,
---@   force?: boolean,
---@   error_on_exist?: boolean,
---@   filter?: function(type: string, path: string) -> boolean,
---@   mode?: integer,
---@   preserve_timestamps?: boolean
---@ }
---@param callback? fun(err?: string, success?: boolean)
---@return boolean?, string? Returns `true` on successful synchronous copy, otherwise `nil` and an error message.
return function(src, dest, options, callback)
  -- Handle optional arguments
  if type(options) == "function" then
    callback = options
    options = {}
  end

  options = options or {}
  options.recursive = options.recursive or false
  options.force = options.force ~= false -- Default to true
  options.error_on_exist = options.error_on_exist or false
  options.filter = options.filter or function()
    return true
  end
  options.mode = options.mode or nil
  options.preserve_timestamps = options.preserve_timestamps or false

  if callback then
    check_exists(src, function(exists, type_)
      if not exists then
        return callback("Source path does not exist: " .. src, false)
      end

      if type_ == "file" then
        copy_file_async(src, dest, function(err, success_)
          vim.print("copy_file_async callback call")
          if not success_ then
            return callback(err, false)
          end

          if options.preserve_timestamps then
            uv.fs_stat(src, function(err_stat, stat_src)
              if not err_stat and stat_src then
                uv.fs_utime(dest, stat_src.atime.sec, stat_src.mtime.sec) -- NOTE: make this with callbac
              end
              callback(nil, true)
            end)
          else
            callback(nil, true)
          end
        end, options)
      elseif type_ == "directory" then
        if not options.recursive then
          return callback("Cannot copy directory without recursive option", false)
        end
        copy_dir_async_recursive(src, dest, function(err, success_)
          if not success_ then
            return callback(err, false)
          end
          callback(nil, true)
        end, options)
      else
        return callback("Unsupported source file type: " .. type_, false)
      end
    end)
  else
    local exists, type_or_err = check_exists(src)
    if not exists then
      return false, type_or_err or "Source path does not exist: " .. src
    end

    if type_or_err == "file" then
      local success, err = copy_file_sync(src, dest, options)
      if not success then
        return false, err
      end

      if options.preserve_timestamps then
        local stat_src, err_stat = uv.fs_stat(src)
        if stat_src then
          uv.fs_utime(dest, stat_src.atime.sec, stat_src.mtime.sec)
        end
      end

      return true
    elseif type_or_err == "directory" then
      if not options.recursive then
        return false, "Cannot copy directory without recursive option"
      end
      local success, err = copy_dir_sync_recursive(src, dest, options)
      if not success then
        return false, err
      end
      return true
    else
      return false, "Unsupported source file type: " .. tostring(type_or_err)
    end
  end
end

-- local entries = FS.readdir(path, { recursive = true })
--
-- if callback then
--   return Callback.waterfall({
--     Callback.build_iteratee(vim.uv.fs_mkdir, to_path, 493),
--     Callback.build_iteratee(Callback.each_series, entries, function(entry, next)
--       if entry.type == "directory" then
--         return vim.uv.fs_mkdir(Path.join(to_path, entry.name), 493, next)
--       end
--
--       return vim.uv.fs_copyfile(Path.join(path, entry.name), Path.join(to_path, entry.name), next)
--     end),
--   }, function(err, result)
--     vim.print("err is:")
--     vim.print(err)
--     vim.print("result is:")
--     vim.print(vim.inspect(result))
--     vim.print("")
--   end)
-- end
--
-- local success, err = vim.uv.fs_mkdir(to_path, 493)
-- if not success then
--   return error(err)
-- end
--
-- List.each(entries, function(entry)
--   if entry.type == "directory" then
--     local success, err = vim.uv.fs_mkdir(Path.join(to_path, entry.name), 493)
--     if not success then
--       return error(err)
--     end
--   else
--     local success, err = vim.uv.fs_copyfile(Path.join(path, entry.name), Path.join(to_path, entry.name))
--     if not success then
--       return error(err)
--     end
--   end
-- end)
--
-- return true
