local uv = vim.uv

---@param path string
---@param options? { flag?: string }
---@param callback? function
---@return string|nil
return function(path, options, callback)
  if type(options) == "function" then
    callback = options
    options = {}
  end

  options = options or {}

  if callback then
    return uv.fs_open(path, options.flag or "r", 438, function(err, fd)
      if err then
        return callback("Error opening file: " .. err, nil)
      end

      uv.fs_fstat(fd, function(err, stat)
        if err then
          uv.fs_close(fd) -- Ensure the file is closed on error
          return callback("Error getting file stats: " .. err, nil)
        end

        if stat.size == 0 then
          uv.fs_close(fd) -- Ensure the file is closed on empty
          return callback(nil, "")
        end

        uv.fs_read(fd, stat.size, 0, function(err, data)
          uv.fs_close(fd) -- Ensure the file is always closed
          callback(err, data)
        end)
      end)
    end)
  end

  -- Blocking mode (sync)
  local fd = assert(uv.fs_open(path, options.flag or "r", 438))
  local stat, err = uv.fs_fstat(fd)
  if not stat then
    uv.fs_close(fd)
    error("Error getting file stats: " .. err)
  end

  if stat.size == 0 then
    uv.fs_close(fd)
    return ""
  end

  local data, err = uv.fs_read(fd, stat.size, 0)
  uv.fs_close(fd)

  if not data then
    error("Error reading file: " .. err)
  end

  return data
end
