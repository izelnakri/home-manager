local uv = vim.loop

---@param path_or_fs string | integer File descriptor number or path
---@param uid integer User id
---@param gid integer User group id
---@param callback? fun(error?: string, success?: boolean)
---@param options? table Options for opening a file if `path_or_fs` is a string
---@return boolean|nil success, if no callback is provided
---@return string|nil error, if no callback is provided and an error occurs
return function(path_or_fs, uid, gid, callback, options)
  options = options or { flag = "r", mode = 438 } -- 438 is 0666 in octal

  -- Helper function to handle errors and success
  local function handle_result(success, error_msg)
    if callback then
      if success then
        callback(nil, true)
      else
        callback(error_msg, false)
      end
    else
      if not success then
        error(error_msg) -- Throw error in synchronous mode
      end
      return true
    end
  end

  -- Function to perform lchown on a file descriptor
  local function perform_lchown(fd)
    local result, err = uv.fs_fchown(fd, uid, gid)
    uv.fs_close(fd) -- Close the file descriptor after the operation
    if err then
      return handle_result(false, "Error changing ownership: " .. tostring(err))
    else
      return handle_result(true)
    end
  end

  if type(path_or_fs) == "string" then
    -- If path_or_fs is a string, open the file first
    local fd, err
    if callback then
      -- Asynchronous operation
      uv.fs_open(path_or_fs, options.flag, options.mode, function(open_err, open_fd)
        vim.print("ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZaa")
        if open_err then
          return callback("Error opening file: " .. tostring(open_err), false)
          -- error("Error opening file: " .. tostring(open_err)) -- Throw error here
        end
        perform_lchown(open_fd)
      end)
    else
      -- Synchronous operation
      fd, err = uv.fs_open(path_or_fs, options.flag, options.mode)
      if not fd then
        error("Error opening file: " .. tostring(err)) -- Throw error here
      end
      return perform_lchown(fd)
    end
  else
    -- If path_or_fs is a file descriptor, directly perform lchown
    return perform_lchown(path_or_fs)
  end
end
