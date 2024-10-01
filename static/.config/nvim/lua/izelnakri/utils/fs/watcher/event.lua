-- NOTE: Only fix the watcher.status = "watching"
-- TODO: BUG #1 - Parent watcher gets watcher.status = "watching" prematurely on options.recursive = true
-- remove, change, rename(? maybe for directory)
local uv = vim.uv
local Path = require("izelnakri.utils.path")
local watched_paths = {} -- Tracks directories being watched
local EVENTS = {
  ADD = "add",
  ADD_DIR = "add_dir",
  CHANGE = "change", -- Not tested yet
  RENAME = "rename", -- Doesnt exist, maybe for directory?
  UNLINK = "unlink",
  UNLINK_DIR = "unlink_dir",
}

local create_watcher
local start_watcher

-- Helper to check if all child watchers have finished initialization
local function all_children_initialized(watcher)
  for _, child_watcher in pairs(watcher.child_watchers) do
    if child_watcher.status ~= "watching" then
      return false
    end
  end
  return true
end

-- Helper to mark watcher status after children have initialized
local function update_watcher_status(watcher)
  if all_children_initialized(watcher) then
    watcher.status = "watching"
    watcher.initialized_at = uv.now()
  end
end

-- Updated function to handle initialization of the stat tree and watchers
local function build_stat_tree_async(watcher, options, callback)
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
                populate_stat_tree(entry_path, function()
                  if not watched_paths[entry_path] then
                    vim.print("entry_path:", entry_path)
                    local child_watcher = create_watcher(entry_path, options, watcher)
                    watcher.child_watchers[entry_path] = child_watcher
                    watched_paths[entry_path] = child_watcher -- Track the new watcher
                    -- NOTE: Change status here?
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

  local function finish_initialization(err)
    if err then
      callback(err)
      return
    end

    -- If this watcher has no child watchers, mark it as "watching"
    if not next(watcher.child_watchers) then
      watcher.status = "watching"
      watcher.initialized_at = uv.now()
    end

    callback(nil, watcher.statTree)

    -- Check if we can set the parent's watcher status to "watching"
    if watcher.parent_watcher then
      update_watcher_status(watcher.parent_watcher)
    end
  end

  -- Start populating the stat tree from the watcher’s path
  populate_stat_tree(watcher.path, finish_initialization)
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
    recursive = true,
  }

  -- Track last event time for debouncing
  local debounce_timers = {}
  local processed_unlink = {} -- Track if unlink/unlink_dir has been processed for a directory

  build_stat_tree_async(watcher, options, function(err)
    if err then
      error(err)
      return
    end

    uv.fs_event_start(watcher.handle, watcher.path, flags, function(err, filename, events)
      -- vim.print(filename)
      -- vim.print("EVENT:")
      -- vim.print(vim.inspect(events))
      if err then
        watcher:stop()
        error("Error watching path: " .. err)
      end

      -- Ignore invalid filenames
      if not filename or filename == "." or filename == ".." or filename == "" then
        vim.print("edge case")
        return
      end

      local filename_targets_watcher_path = watcher.statTree[watcher.path]
        and (watcher.statTree[watcher.path].type == "directory")
        and (Path.basename(watcher.path) == filename)
      if filename_targets_watcher_path then
        vim.print("filename_targets_watcher_path diversion")
        return
      end

      local full_path = (filename_targets_watcher_path and watcher.path) or Path.join(watcher.path, filename)

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

        -- Stat the file or directory asynchronously
        uv.fs_stat(full_path, function(err, current_stat)
          local old_entry = watcher.statTree[full_path]
          local event_entry = { filename = full_path, fs_events = events }

          -- Handle unlink/unlink_dir events
          if not old_entry and current_stat then
            event_entry.event = current_stat.type == "directory" and EVENTS.ADD_DIR or EVENTS.ADD
            watcher.statTree[full_path] = { type = current_stat.type, stat = current_stat }

            if event_entry.event == EVENTS.ADD_DIR then
              local child_watcher = create_watcher(full_path, options, watcher) -- NOTE: should this be the outer most parent_watcher?
              watcher.child_watchers[full_path] = child_watcher -- TODO: maybe move these inside the create_watcher?
              watched_paths[full_path] = child_watcher
            end
          elseif not current_stat then
            event_entry.event = old_entry.type == "directory" and EVENTS.UNLINK_DIR or EVENTS.UNLINK
            watcher.statTree[full_path] = nil
          elseif current_stat.mtime ~= old_entry.stat.mtime then
            event_entry.event = EVENTS.CHANGE
            watcher.statTree[full_path] = { type = current_stat.type, stat = current_stat }
          else
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

    -- Update parent watcher status if all child watchers are ready
    if watcher.parent_watcher then
      update_watcher_status(watcher.parent_watcher)
    end

    -- Update own status if it has no children
    update_watcher_status(watcher)
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
  }

  start_watcher(watcher, options)
  return watcher
end

-- FS.watch
local function FS_watch(path, options, callback)
  if watched_paths[path] then
    error("Already watching path: " .. path)
  elseif type(options) == "function" or (getmetatable(options) and getmetatable(options).__call) then
    callback = options
    options = {}
  end

  local watcher = create_watcher(path, options)
  watcher:add_callback(callback)

  return watcher
end

-- FS.unwatch
local function FS_unwatch(watcher)
  watcher:stop()
  watched_paths[watcher.path] = nil
end

return {
  watch = FS_watch,
  unwatch = FS_unwatch,
}
