local uv = vim.uv

---@param path string
---@param data string
---@param options? { mode?: integer, flag?: string, flush?: boolean }
---@param callback? function
return function(path, data, options, callback)
  if type(options) == "function" then
    callback = options
    options = {}
  end

  assert(type(path) == "string", "path must be a string")
  assert(type(data) == "string", "data must be a string")
  options = options or {}

  local mode = options.mode or 438 -- Default mode (0o666)
  local flag = options.flag or "w" -- Default to append mode

  if callback then
    uv.fs_open(path, flag, mode, function(err, fd)
      if err then
        uv.fs_close(fd)
        return callback(err)
      end

      uv.fs_write(fd, data, 0, function(err, bytes_written)
        if err then
          uv.fs_close(fd)
          return callback(err)
        end

        if options.flush then
          uv.fs_fsync(fd, function(err)
            uv.fs_close(fd)
            if err then
              return callback(err)
            end

            return callback(nil, bytes_written)
          end)
        else
          uv.fs_close(fd, function(err)
            if err then
              return callback(err)
            end

            return callback(nil, bytes_written)
          end)
        end
      end)
    end)
  else
    -- Synchronous version
    local fd, err = uv.fs_open(path, flag, mode)
    if not fd then
      error("Failed to open file: " .. err)
    end

    local bytes_written, write_err = uv.fs_write(fd, data, 0)
    if write_err then
      uv.fs_close(fd)
      error("Failed to write to file: " .. write_err)
    end

    if options.flush then
      uv.fs_fsync(fd)
    end

    uv.fs_close(fd)
    return bytes_written
  end
end
