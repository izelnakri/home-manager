-- NOTE: Only fix the watcher.status = "watching"
-- TODO: BUG #1 - Parent watcher gets watcher.status = "watching" prematurely on options.recursive = true
-- remove, change, rename(? maybe for directory -> it is unlink then add)
-- Implement array of paths watching
-- watching paths need to be immutable: it can detect re-adds, renames(unlink + add)

local uv = vim.uv
local Path = require("izelnakri.utils.path")
local WATCHERS = {} -- Tracks directories being watched
local unlinked_paths = {} -- Keeps track of unlinked paths temporarily for rename detection
local EVENTS = {
  ADD = "add",
  ADD_DIR = "add_dir",
  CHANGE = "change",
  UNLINK = "unlink",
  UNLINK_DIR = "unlink_dir",
}

-- NOTE: when path not exists, one can build a retry loop, or a parent directory watcher(which can execute the same handler without having to do populate)

local create_watcher
local start_watcher
local handle_fs_event
local register_recovery_watcher_for

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

-- Updated function to handle initialization of the stat tree and watchers | handle_unlink_event -> does it on unlink or rename then runs it on the fs_event inside start_watcher
local function build_stat_tree_async(watcher, options, callback)
  local function populate_stat_tree(current_path, parent_watcher, done_callback)
    uv.fs_stat(current_path, function(err, stat)
      if err then
        return done_callback("Failed to stat: " .. current_path)
      end

      if stat.type == "directory" then
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
                uv.fs_stat(entry_path, function(err, entry_stat)
                  if not err then
                    watcher.statTree[entry_path] = { type = entry.type, stat = entry_stat }
                  end

                  -- For subdirectories, ensure we start a watcher only if not already watched
                  if entry.type == "directory" and options.recursive then
                    -- TODO: This gets called on each watcher:restart() and create_watcher

                    local child_watcher = create_watcher(entry_path, options, parent_watcher) -- NOTE: This is not correct, watcher as to be parent_watcher

                    populate_stat_tree(entry_path, child_watcher, function()
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
      else -- Handle file path case
        vim.print("path is a file:", current_path)
        watcher.statTree[current_path] = { type = "file", stat = stat }
        -- NOTE: Should I add WATCHERS[current_path] = watcher ?
        done_callback(nil, watcher.statTree)
      end
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

  if watcher.statTree[watcher.path] then
    return finish_initialization()
  end

  -- Start populating the stat tree from the watcher’s path
  populate_stat_tree(watcher.path, watcher, finish_initialization)
end

-- NOTE: maybe in future use this
-- local function register_fs_event(watcher, options)
-- end

local start_fs_event
start_fs_event = function(watcher, options)
  local flags = {
    watch_entry = true, -- Watch directory entries
    stat = true, -- Enable stat info
    recursive = true,
  }

  -- Track last event time for debouncing
  local debounce_timers = {}
  uv.fs_event_start(watcher.handle, watcher.path, flags, function(err, filename, fs_event)
    -- vim.print(filename)
    -- vim.print("EVENT:")
    -- vim.print(vim.inspect(fs_event))
    if err then
      -- watcher:stop()
      return error("Error watching path: " .. err)
    end

    if not filename or filename == "." or filename == ".." or filename == "" then -- Ignore invalid filenames
      vim.print("edge case, check which one!!")
      return
    end

    local known_watcher_type = watcher.statTree[watcher.path] and watcher.statTree[watcher.path].type
    local filename_targets_watcher_path = known_watcher_type == "directory"
      and (Path.basename(watcher.path) == filename)
    if filename_targets_watcher_path then
      vim.print("filename_targets_watcher_path diversion")
      return
    end

    local full_path
    if known_watcher_type == "file" then
      full_path = watcher.path
    else
      full_path = (filename_targets_watcher_path and watcher.path) or Path.join(watcher.path, filename)
      -- TODO: Maybe here I need to add known_watcher_type == "file" thing
    end

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

      uv.fs_stat(full_path, function(err, current_stat)
        handle_fs_event(watcher, options, full_path, current_stat, fs_event)
      end)
    end)
  end)

  -- Mark this path as watched only after starting the watcher
  if WATCHERS[watcher.path] then
    table.insert(WATCHERS[watcher.path], watcher)
  else
    WATCHERS[watcher.path] = { watcher }
  end

  -- Update parent watcher status if all child watchers are ready
  if watcher.parent_watcher then
    update_watcher_status(watcher.parent_watcher)
  end

  -- Update own status if it has no children
  update_watcher_status(watcher)
end

start_watcher = function(watcher, options)
  vim.print("start_watcher runs for:", watcher.path)

  -- Avoid starting a watcher if already watching this path
  if watcher.status == "watching" then
    -- NOTE: Would this ever hit? Maybe throw an exception to check
    return
  end

  uv.fs_stat(watcher.path, function(err, stat)
    if err then -- When watcher.path doesnt exist, it has a retry timer every sec to poll for it
      -- TODO: instead create a recovery_watcher here(?)
      register_recovery_watcher_for(watcher, watcher.path, options)

      -- local retry_timer = uv.new_timer()
      -- uv.timer_start(retry_timer, 1000, 0, function()
      --   uv.fs_stat(watcher.path, function(retry_err, retry_stat)
      --     if not retry_err then
      --       uv.timer_stop(retry_timer)
      --       retry_timer:close()
      --       watcher.statTree[watcher.path] = { type = retry_stat.type, stat = retry_stat }
      --
      --       return start_watcher(watcher, options)
      --     end
      --   end)
      -- end)
    else
      if watcher.handle == nil then
        watcher.handle = uv.new_fs_event()
      end

      build_stat_tree_async(watcher, options, function(err)
        if err then
          error(err)
        end

        -- NOTE: add an if check for *not stopped* for the retry poll in the future here, a race condition via retries on non-existing at initial watch
        start_fs_event(watcher, options)
      end)
    end
  end)
end

local function register_child_watcher_until_main_watcher(watcher, parent_watcher)
  table.insert(parent_watcher.child_watchers, watcher)

  if parent_watcher.parent_watcher then
    register_child_watcher_until_main_watcher(watcher, parent_watcher.parent_watcher)
  end
end

create_watcher = function(path, options, parent_watcher) -- NOTE: sometimes parent_watcher can be few levels above
  options = options or {}

  -- Use the parent watcher’s statTree if present
  local statTree = parent_watcher and parent_watcher.statTree or {}
  local main_watcher = (parent_watcher and parent_watcher.main_watcher) or parent_watcher

  local watcher = {
    path = path, -- NOTE: maybe normalize path to make it absolute always
    main_watcher = main_watcher,
    handle = nil,
    child_watchers = {}, -- NOTE: This is different object per watcher
    parent_watcher = parent_watcher,
    callbacks = (main_watcher and main_watcher.callbacks) or {},
    statTree = statTree, -- NOTE: This one is global cache, important for generating "change" event
    recovery_watcher = nil, -- TODO: maybe this is needed in future for unlinks
    status = "initialized",
    initialized_at = nil,

    get_watched_paths = function(self) -- NOTE: important to see what to clear(?)
      local result = {}
      for key, _ in pairs(statTree) do
        if String.starts_with(key, self.path) then -- NOTE: is this correct?
          List.push(result, key)
        end
      end

      return result
    end,

    add_callback = function(self, cb)
      table.insert(self.callbacks, cb)

      for _, child in pairs(self.child_watchers) do
        child:add_callback(cb)
      end
    end,

    -- NOTE: instead coupled_watcher has to be child_watchers and each has its position in the tree
    -- It cant be Watchers tree because multiple watchers can be registered under a tree
    stop = function(self)
      if self.handle and self.status ~= "stopped" then
        vim.print("CLOSING..", self.path, self.handle:getpath())
        self.handle:close()
        self.status = "stopped"

        for _, child_path in pairs(self:get_watched_paths()) do
          self.statTree[child_path] = nil
        end
        self.statTree[self.path] = nil -- NOTE: Probably needed

        -- NOTE: calls each time, should call once(?)
        for _, child in pairs(self.child_watchers) do
          child:stop()
        end

        if self.recovery_watcher then
          self.recovery_watcher:stop()
        end
      end
    end,

    unwatch = function(self)
      self:stop()

      for index, child_watcher in ipairs(self.child_watchers) do
        child_watcher:stop()

        List.delete(WATCHERS[child_watcher.path], child_watcher)
        table.remove(self.child_watchers, index)
      end

      return self
    end,

    -- NOTE: This is not tested yet
    restart = function(self)
      if self.handle then
        self:stop()
      end

      start_watcher(self, options)

      return self
    end,
  }

  if parent_watcher then
    register_child_watcher_until_main_watcher(watcher, parent_watcher)
  end

  start_watcher(watcher, options)

  return watcher
end

-- This on suggestion runs on build_stat_tree_async(?), is this good on major renaming a directory(?) -> yes?, check this with FS.cp
register_recovery_watcher_for = function(outermost_parent_watcher, lost_watcher_path, options) -- NOTE: watcher is outermost_parent_watcher?
  options = options or {}

  local parent_dir = Path.dirname(lost_watcher_path)
  vim.print(
    "REGISTERING TOP-LEVEL WATCHER: full_path is: ",
    lost_watcher_path,
    " watcher.path is: ",
    outermost_parent_watcher.path,
    " parent_dir to register is: ",
    parent_dir
  )

  -- NOTE: probably not needed
  -- if outermost_parent_watcher.recovery_watcher then
  --   outermost_parent_watcher.recovery_watcher:unwatch()
  -- end

  outermost_parent_watcher.recovery_watcher = create_watcher(parent_dir, {}) -- NOTE: what if the parent watcher already exists?, it takes some time to actually create the listener
  outermost_parent_watcher.recovery_watcher:add_callback(function(event, event_path, stat)
    vim.print("RECOVERY ADD CALL", event, event_path)
    if (event == EVENTS.ADD or event == EVENTS.ADD_DIR) and event_path == lost_watcher_path then
      uv.fs_stat(lost_watcher_path, function(_, stat)
        outermost_parent_watcher:restart()
        for _, cb in ipairs(outermost_parent_watcher.callbacks) do
          cb(event, lost_watcher_path, stat)
        end

        outermost_parent_watcher.recovery_watcher:unwatch() -- TODO: Should this be stop instead?
        outermost_parent_watcher.recovery_watcher = nil
      end)
    end
  end)
end

-- Updated function to handle unlink and add events
handle_fs_event = function(watcher, options, full_path, current_stat, fs_event)
  vim.print("full_path: ", full_path)
  -- p(old_entry)
  -- p(current_stat)
  local old_entry = watcher.statTree[full_path] -- TODO: This exists(?)
  local event_entry = { filename = full_path, fs_event = fs_event }

  -- Handle unlink/unlink_dir events
  if not old_entry and current_stat then
    event_entry.event = current_stat.type == "directory" and EVENTS.ADD_DIR or EVENTS.ADD
    watcher.statTree[full_path] = { type = current_stat.type, stat = current_stat }

    if unlinked_paths[full_path] then
      unlinked_paths[full_path] = nil -- Remove from unlinked tracking
    end

    if event_entry.event == EVENTS.ADD_DIR and options.recursive then
      if full_path == watcher.path then
        vim.print("IZZZZZZZZZZZEL THIS HAPPENSSS!, so do NOT remove the if check below: full_path ~= watcher.path")
      end

      if full_path ~= watcher.path then
        local child_watcher = create_watcher(full_path, options, watcher) -- TODO: !!! This is sometimes watcher, sometimes parent_watcher?
      end
    end
  elseif not current_stat then
    if old_entry == nil then
      vim.print("OLD_ENTRY EMPTY FOR:")
      vim.print(full_path)
      vim.print(watcher.path)
    end
    event_entry.event = (old_entry.type == "directory" and EVENTS.UNLINK_DIR) or EVENTS.UNLINK

    watcher.statTree[full_path] = nil -- TODO: Remove also all subdirectories and files, Also subdirectory watchers

    unlinked_paths[full_path] = true -- TODO: Maybe unlinked_paths not needed(?)

    if (old_entry.type == "directory") and options.recursive then
      vim.print("CLEAAARING: full_path is: ", full_path, " watcher.path is: ", watcher.path)
      local target_watcher = List.find(watcher.child_watchers, function(child_watcher)
        return child_watcher.path == full_path
      end)

      target_watcher:unwatch()
    end

    if watcher.parent_watcher == nil and full_path == watcher.path then -- NOTE: maybe this causes problems
      register_recovery_watcher_for(watcher, full_path, options) -- NOTE: This doesnt remove the removed folder watcher, which shouldnt fire multiple events?
    end
  elseif current_stat.mtime ~= old_entry.stat.mtime then
    event_entry.event = EVENTS.CHANGE
    watcher.statTree[full_path] = { type = current_stat.type, stat = current_stat }
  else
    vim.print("RARE CASE, does it ever happen?")
    return
  end

  for _, cb in ipairs(watcher.callbacks) do
    cb(event_entry.event, event_entry.filename, current_stat)
  end
end

-- FS.watch
local function FS_watch(path, options, callback)
  if WATCHERS[path] and List.any(WATCHERS[path], function(watcher)
    return watcher.main_watcher == nil
  end) then
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
  return watcher:unwatch()
end

return {
  watch = FS_watch,
  unwatch = FS_unwatch,
}
