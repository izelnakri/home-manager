local Path = require("izelnakri.utils.path")

local function recursive_readdir_sync(current_path, options, current_depth)
  options.result = options.result or {}
  current_depth = current_depth or 0

  local scandir, err = vim.uv.fs_scandir(current_path)
  if not scandir then
    return nil, error("Failed to open directory: " .. current_path)
  end

  while true do
    local name, type_ = vim.uv.fs_scandir_next(scandir)
    if not name then
      break
    end

    local entry_path = Path.join(current_path, name)

    table.insert(options.result, {
      name = entry_path,
      type = type_,
    })

    if type_ == "directory" and options.recursive and (not options.depth or current_depth < options.depth) then
      recursive_readdir_sync(entry_path, options, current_depth + 1)
    end
  end

  local filtered_results = {}
  for _, entry in ipairs(options.result) do
    if options.filter(entry.type, entry.name) then
      table.insert(filtered_results, entry)
    end
  end

  return filtered_results
end

local function recursive_readdir_async(current_dir, options, current_depth, callback)
  options.result = options.result or {}
  current_depth = current_depth or 0

  vim.uv.fs_opendir(current_dir, function(err, dir_handle)
    if err then
      return callback("Failed to open directory: " .. current_dir, nil)
    end

    local function read_dir()
      vim.uv.fs_readdir(dir_handle, function(err, entries)
        if err then
          return callback("Error reading directory: " .. current_dir, nil)
        end

        if not entries then
          vim.uv.fs_closedir(dir_handle)
          local filtered_results = {}
          for _, entry in ipairs(options.result) do
            if options.filter(entry.type, entry.name) then
              table.insert(filtered_results, entry)
            end
          end
          return callback(nil, filtered_results)
        end

        for _, entry in ipairs(entries) do
          local entry_path = Path.join(current_dir, entry.name)
          table.insert(options.result, {
            name = entry_path,
            type = entry.type,
          })

          if
            entry.type == "directory"
            and options.recursive
            and (not options.depth or current_depth < options.depth)
          then
            recursive_readdir_async(entry_path, options, current_depth + 1, function()
              read_dir()
            end)
          else
            read_dir()
          end
        end
      end)
    end

    read_dir()
  end, options.max_entry_size)
end

---@param path_or_dir string | userdata Path or Dir entry from vim.uv.fs_opendir
---@param options { recursive: boolean, max_entry_size?: number, depth: number, filter: fun(type, path) }
---@param callback? function(err?: string, entries?: { name: string, type: string })
return function(path_or_dir, options, callback)
  if type(options) == "function" then
    callback = options
    options = {}
  end
  options = options or {}
  options.recursive = options.recursive or false
  options.depth = options.depth or nil
  options.filter = options.filter or function()
    return true
  end

  if callback then
    vim.uv.fs_stat(path_or_dir, function(err, stat)
      if err then
        return callback(err, nil)
      elseif not stat then
        return callback("Path does not exist: " .. path_or_dir, nil)
      elseif stat.type ~= "directory" then
        return callback("Path is not a directory: " .. path_or_dir, nil)
      end

      recursive_readdir_async(path_or_dir, options, 0, callback)
    end)
  else
    local stat = vim.uv.fs_stat(path_or_dir)
    if not stat then
      return nil, error("Path does not exist: " .. path_or_dir)
    elseif stat.type ~= "directory" then
      return nil, error("Path is not a directory: " .. path_or_dir)
    end

    return recursive_readdir_sync(path_or_dir, options, 0)
  end
end