-- NOTE: This doesnt watch recursively correctly!
local uv = vim.uv
local Path = require("izelnakri.utils.path")
local watchers = {} -- Store active watchers globally
local EVENTS = {
  ADD = "add",
  ADD_DIR = "add_dir",
  CHANGE = "change",
  RENAME = "rename",
  UNLINK = "unlink",
  UNLINK_DIR = "unlink_dir",
}

local create_watcher
local start_watcher
local function build_stat_tree_async(watcher, options, callback)
  local statTree = {}

  local function populate_stat_tree(current_path, done_callback)
    uv.fs_opendir(current_path, function(err, dir_handle)
      if err then
        return done_callback("Failed to open directory: " .. current_path)
      end

      local function read_dir()
        uv.fs_readdir(dir_handle, function(err, entries)
          if err then
            return done_callback("Error reading directory: " .. current_path)
          end

          if not entries then
            uv.fs_closedir(dir_handle)
            return done_callback(nil, statTree)
          end

          -- Process each entry
          local pending = #entries
          local function on_entry_processed()
            pending = pending - 1
            if pending == 0 then
              read_dir() -- Continue reading next batch of entries
            end
          end

          for _, entry in ipairs(entries) do
            local entry_path = Path.join(current_path, entry.name)

            -- Stat each file/directory asynchronously
            uv.fs_stat(entry_path, function(err, stat)
              if not err then
                statTree[entry_path] = { type = entry.type, stat = stat }
              end

              -- Start a watcher for subdirectories when the recursive option is enabled
              if entry.type == "directory" and options.recursive then
                -- Start a watcher for this subdirectory
                -- TODO: Check this because it needs to be ready as well and done
                start_watcher(create_watcher(entry_path, options, watcher.callbacks), options)
                -- Recursively populate stat tree for subdirectories
                populate_stat_tree(entry_path, on_entry_processed)
              else
                on_entry_processed()
              end
            end)
          end
        end)
      end

      read_dir() -- Start reading the directory
    end)
  end

  populate_stat_tree(watcher.path, callback)
end

start_watcher = function(watcher, options)
  watcher.handle = uv.new_fs_event()

  -- Determine flags based on options
  local flags = {
    watch_entry = true, -- Default not to watch individual entries
    stat = true, -- Default not to stat
    recursive = options.recursive or false, -- Set recursive flag based on options
  }

  build_stat_tree_async(watcher, options, function(err, statTree)
    if err then
      error(err)
      return
    end

    watcher.statTree = statTree

    -- Track the last event time and debounce it
    local debounce_timers = {}

    -- NOTE: Watcher logic
    uv.fs_event_start(watcher.handle, watcher.path, flags, function(err, filename, events)
      if err then
        watcher:stop() -- Stop on error
        error("Error watching path: " .. err)
      end

      local full_path = Path.join(watcher.path, filename)
      local event_entry = { filename = full_path, fs_events = events }

      -- Debounce timer for the event
      if debounce_timers[full_path] then
        uv.timer_stop(debounce_timers[full_path]) -- Clear previous timer
      end

      -- Create a new debounce timer
      debounce_timers[full_path] = uv.new_timer()
      uv.timer_start(debounce_timers[full_path], 100, 0, function()
        uv.timer_stop(debounce_timers[full_path]) -- Stop and close the timer after execution
        debounce_timers[full_path]:close()
        debounce_timers[full_path] = nil

        -- Stat the file or directory asynchronously to compare with the statTree
        uv.fs_stat(full_path, function(err, current_stat)
          -- vim.print("EVENT CALL")
          -- vim.print(full_path)
          local old_entry = watcher.statTree[full_path]

          if not old_entry then
            -- New file or directory added
            if current_stat and current_stat.type == "directory" then
              event_entry.event = EVENTS.ADD_DIR -- Directory added
            else
              event_entry.event = EVENTS.ADD -- File added
            end
          elseif not current_stat then
            -- File or directory removed
            if old_entry.type == "directory" then
              event_entry.event = EVENTS.UNLINK_DIR -- Directory removed
            else
              event_entry.event = EVENTS.UNLINK -- File removed
            end
            watcher.statTree[full_path] = nil
          elseif current_stat.mtime ~= old_entry.stat.mtime then
            -- File or directory modified
            event_entry.event = "change"
          else
            vim.print("SKIP CALL")
            -- Skip unneeded duplicate events
            return
          end

          -- Update the statTree
          watcher.statTree[full_path] = { type = current_stat.type, stat = current_stat }

          -- Trigger all registered callbacks
          for _, cb in ipairs(watcher.callbacks) do
            cb(event_entry.event, event_entry.filename, current_stat)
          end

          -- If recursive, ensure subdirectories are being watched
          if events == "rename" and options.recursive and event_entry.event == "add" then
            uv.fs_stat(full_path, function(err, stat) -- NOTE: is this necessary? or buggy? Check if it can be removed
              if not err and stat.type == "directory" then
                -- Start a watcher for the newly added directory
                local new_watcher = create_watcher(full_path, options, watcher.callbacks)
                table.insert(watchers[watcher.path], new_watcher)
              end
            end)
          end
        end)
      end)
    end)

    watcher.status = "watching"
    watcher.initialized_at = uv.now()
  end)
end

-- NOTE: maybe change callbacks param to parent watcher and include the relationships inside the watcher objects
create_watcher = function(path, options, callbacks)
  options = options or {}

  local watcher = {
    path = path,
    callbacks = callbacks or {},
    statTree = {}, -- Store stat information for path and subdirectories
    status = "initialized",
    initialized_at = nil,
    entries = {},

    -- Add a new callback to be triggered on events
    add_callback = function(self, cb)
      table.insert(self.callbacks, cb)
      -- TODO: add it to all sub directories too
    end,

    stop = function(self)
      if self.handle then
        uv.fs_event_stop(self.handle) -- NOTE: Does this stop also subdirectories?, related watchers(?)
        self.handle:close()
        self.status = "stopped"
      end
    end,

    restart = function(self)
      if self.handle then
        self:stop() -- Stop first
      end
      start_watcher(self, options)
    end,

    initialize = function(self)
      start_watcher(self, options)
    end,
  }

  -- Automatically start the watcher upon creation
  watcher:initialize()

  return watcher
end

--- Watches a directory or file for changes with an optional recursive option.
--- @param path string: The path to watch.
--- @param options table|nil: Optional table with settings. { recursive = boolean }
--- @param callback function: A callback function triggered when an event occurs. The callback will receive (event(create | modify | remove) filename), maybe also directory type(if its not an extra syscall).
--- @return watcher: The watcher handle that can be used for unwatching. { callbacks = function[], stop = function, restart = function, status = string, initialized_at = number, entries = entry[] }
local function FS_watch(path, options, callback)
  if type(options) == "function" or (getmetatable(options) and getmetatable(options).__call) then
    callback = options
    options = {}
  end
  -- Create a new watcher object
  local watcher = create_watcher(path, options, { callback })

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
