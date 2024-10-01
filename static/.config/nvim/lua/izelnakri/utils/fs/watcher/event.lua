local uv = vim.uv
local Path = require("izelnakri.utils.path")
local watched_paths = {} -- Tracks directories being watched
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
  local function populate_stat_tree(current_path, parent_watcher, done_callback)
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
            return done_callback(nil, watcher.statTree)
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
                watcher.statTree[entry_path] = { type = entry.type, stat = stat }
              end

              -- For subdirectories, ensure we start a watcher only if not already watched
              if entry.type == "directory" and options.recursive then
                -- Recursively populate the stat tree and create a new watcher for subdirectory
                populate_stat_tree(entry_path, watcher, function()
                  if not watched_paths[entry_path] then
                    local child_watcher = create_watcher(entry_path, options, watcher)
                    watcher.child_watchers[entry_path] = child_watcher
                    watched_paths[entry_path] = child_watcher -- LLM SUGGESTION, MAYBE REMOVE: Ensure to track the new watcher
                  end
                  on_entry_processed()
                end)
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

  populate_stat_tree(watcher.path, nil, callback)
end

local initialize_event_handling = function(watcher)
  -- Handle specific events if needed
end

start_watcher = function(watcher, options)
  vim.print("start_watcher runs for:", watcher.path)
  -- Avoid starting a watcher if already watching this path
  if watcher.status == "watching" then
    return
  end

  watcher.handle = uv.new_fs_event()

  local flags = {
    watch_entry = true, -- Watch directory entries
    stat = true, -- Enable stat info
    recursive = options.recursive or false, -- Set recursive flag based on options
  }

  build_stat_tree_async(watcher, options, function(err)
    if err then
      error(err)
      return
    end

    -- Track last event time for debouncing
    local debounce_timers = {}

    uv.fs_event_start(watcher.handle, watcher.path, flags, function(err, filename, events)
      if err then
        watcher:stop()
        error("Error watching path: " .. err)
      end

      -- NOTE: Maybe remove: Ensure we have a valid filename
      if filename == "." or filename == ".." then
        return -- Ignore these entries as they don't represent valid events
      end

      local full_path = Path.join(watcher.path, filename)

      -- NOTE: Maybe remove: Optionally log or check for valid paths
      if full_path == watcher.path then
        return -- Avoid processing if the full_path is the same as the watcher path
      end

      local event_entry = { filename = full_path, fs_events = events }

      -- Debounce timer for the event
      if debounce_timers[full_path] then
        uv.timer_stop(debounce_timers[full_path])
        debounce_timers[full_path]:close()
      end

      debounce_timers[full_path] = uv.new_timer()
      uv.timer_start(debounce_timers[full_path], 100, 0, function()
        uv.timer_stop(debounce_timers[full_path])
        debounce_timers[full_path]:close()
        debounce_timers[full_path] = nil

        vim.print("call for ", full_path)
        -- Stat the file or directory asynchronously
        uv.fs_stat(full_path, function(err, current_stat) -- NOTE: on unlink should I call fs_stat?
          local old_entry = watcher.statTree[full_path]

          if not old_entry and current_stat then
            event_entry.event = current_stat.type == "directory" and EVENTS.ADD_DIR or EVENTS.ADD
            watcher.statTree[full_path] = { type = current_stat.type, stat = current_stat }
          elseif not current_stat then
            event_entry.event = old_entry.type == "directory" and EVENTS.UNLINK_DIR or EVENTS.UNLINK
            watcher.statTree[full_path] = nil
          elseif current_stat.mtime ~= old_entry.stat.mtime then
            event_entry.event = EVENTS.CHANGE
            watcher.statTree[full_path] = { type = current_stat.type, stat = current_stat }
          else
            vim.print("pass")
            return
          end

          -- Trigger all registered callbacks
          for _, cb in ipairs(watcher.callbacks) do
            cb(event_entry.event, event_entry.filename, current_stat)
          end
        end)
      end)
    end)

    -- Mark this path as watched only after starting the watcher
    watched_paths[watcher.path] = true
    watcher.status = "watching"
    watcher.initialized_at = uv.now()
  end)
end

create_watcher = function(path, options, parent_watcher)
  options = options or {}

  -- Use the parent watcher’s statTree if present
  local statTree = parent_watcher and parent_watcher.statTree or {}

  local watcher = {
    path = path,
    parent_watcher = parent_watcher,
    callbacks = (parent_watcher and parent_watcher.callbacks) or {},
    statTree = statTree,
    child_watchers = {},
    status = "initialized",
    initialized_at = nil,

    add_callback = function(self, cb)
      table.insert(self.callbacks, cb)

      for _, child in pairs(self.child_watchers) do
        child:add_callback(cb)
      end
    end,

    stop = function(self)
      if self.handle then
        uv.fs_event_stop(self.handle)
        self.handle:close()
        self.status = "stopped"
      end
      for _, child in pairs(self.child_watchers) do
        child:stop()
      end
    end,

    restart = function(self)
      if self.handle then
        self:stop()
      end
      start_watcher(self, options)
      for _, child in pairs(self.child_watchers) do
        child:restart()
      end
    end,

    initialize = function(self)
      start_watcher(self, options)
    end,
  }

  watcher:initialize()
  return watcher
end

local function FS_watch(path, options, callback)
  if type(options) == "function" or (getmetatable(options) and getmetatable(options).__call) then
    callback = options
    options = {}
  end

  local watcher = create_watcher(path, options, nil)
  watcher:add_callback(callback)

  return watcher
end

local function FS_unwatch(path, watcher_to_remove)
  if watched_paths[path] then
    for i, watcher in ipairs(watched_paths[path]) do
      if watcher == watcher_to_remove then
        watcher:stop()
        table.remove(watched_paths[path], i)
        if #watched_paths[path] == 0 then
          watched_paths[path] = nil
        end
        return true
      end
    end
  end
  return false
end

return {
  watch = FS_watch,
  unwatch = FS_unwatch,
}
