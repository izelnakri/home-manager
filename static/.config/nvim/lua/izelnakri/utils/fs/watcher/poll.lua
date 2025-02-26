local uv = vim.uv
local watchers = {} -- Store active watchers globally

-- Helper function to stop a watcher
local function stop_watcher(watcher)
  if watcher.handle then
    uv.fs_poll_stop(watcher.handle)
    watcher.handle:close()
    watcher.status = "stopped"
  end
end

-- Helper function to start a watcher
local function start_watcher(watcher, path, options)
  watcher.handle = uv.new_fs_poll()

  -- Set the polling interval (default to 500ms)
  local interval = options.interval or 500

  -- Start polling the provided path using uv.fs_poll_start
  uv.fs_poll_start(watcher.handle, path, interval, function(err, prev, curr)
    if err then
      watcher:stop() -- Stop on error
      error("Error watching path: " .. err)
    end

    -- Create an event entry for the callback
    local event_entry = { prev = prev, curr = curr }
    vim.print("event_entry is:")
    vim.print(vim.inspect(event_entry))
    vim.print("")
    vim.print(err)
    table.insert(watcher.entries, event_entry)
    vim.print(uv.fs_poll_getpath(watcher.handle)) -- NOTE: gets the handle but not the path
    vim.print("zz")

    -- Trigger all registered callbacks
    for _, cb in ipairs(watcher.callbacks) do
      cb(event_entry)
    end
  end)

  watcher.status = "watching"
  watcher.initialized_at = uv.now()
end

-- Watcher structure
local function create_watcher(path, options)
  options = options or {}

  local watcher = {
    callbacks = {},
    status = "initialized",
    initialized_at = nil,
    entries = {},

    -- Add a new callback to be triggered on events
    add_callback = function(self, cb)
      table.insert(self.callbacks, cb)
    end,

    -- Stop the watcher
    stop = function(self)
      stop_watcher(self)
    end,

    -- Restart the watcher
    restart = function(self)
      if self.handle then
        self:stop() -- Stop first
      end
      start_watcher(self, path, options)
    end,

    -- Initialize and start the watcher
    initialize = function(self)
      start_watcher(self, path, options)
    end,
  }

  -- Automatically start the watcher upon creation
  watcher:initialize()

  return watcher
end

--- Watches a directory or file for changes with a polling mechanism.
--- @param path string: The path to watch.
--- @param options table|nil: Optional table with settings. { interval = number }
--- @param callback function: A callback function triggered when an event occurs. The callback will receive (prev, curr).
--- @return watcher: The watcher handle that can be used for unwatching. { callbacks = function[], stop = function, restart = function, status = string, initialized_at = number, entries = entry[] }
local function FS_watch(path, options)
  -- Create a new watcher object
  local watcher = create_watcher(path, options)

  -- Store the watcher in a global table using path as the key
  watchers[path] = watchers[path] or {}
  table.insert(watchers[path], watcher)

  return watcher
end

-- FS.unwatch implementation
local function FS_unwatch(path, watcher_to_remove)
  -- Check if watchers exist for the provided path
  if watchers[path] then
    for i, watcher in ipairs(watchers[path]) do
      if watcher == watcher_to_remove then
        -- Stop and remove the watcher
        watcher:stop()
        table.remove(watchers[path], i)

        -- Clean up the path entry if no more watchers exist
        if #watchers[path] == 0 then
          watchers[path] = nil
        end
        return true
      end
    end
  end
  return false -- Watcher not found
end

-- Export FS module
return {
  watchers = watchers,
  watch = FS_watch,
  unwatch = FS_unwatch,
}
