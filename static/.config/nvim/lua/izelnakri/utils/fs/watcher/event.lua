-- during traversal, if there is a symlink, create a separate watcher for that symlink! - what happens when this symlink gets deleted AND when it gets recreated during watch(this works currently?)
-- TODO: BUG #1 - Parent watcher gets watcher.status = "watching" prematurely on options.recursive = true
-- TODO: BUG #2 - Individual symlinked files are not being watched properly
-- This creates a problem with the current recovery watcher mechanism
-- symlinking new

-- NOTE: Add watcher.status = recovery | initialized, watching, recovery(after recovery sets up), stopped
-- NOTE: Make ADD_DIR and UNLINK_DIR recursive(?)

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
                  -- vim.print("found path:", entry_path)

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
                  elseif entry.type == "link" and entry_stat ~= nil then
                    local child_watcher = create_watcher(entry_path, options, parent_watcher) -- NOTE: This is not correct, watcher as to be parent_watcher

                    on_entry_processed()
                  else
                    on_entry_processed()
                  end
                end)
              end
            end)
          end

          read_dir() -- Start reading the directory
        end)
      else
        vim.print("path is a file:", current_path)
        watcher.statTree[current_path] = { type = "file", stat = stat }
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

local start_fs_event
start_fs_event = function(watcher, options)
  local flags = {
    watch_entry = true, -- Watch directory entries
    stat = true, -- Enable stat info
    recursive = true,
  }

  -- Track last event time for debouncing
  local debounce_timers = {}
  -- vim.print("handle registration:", watcher.path)
  uv.fs_event_start(watcher.handle, watcher.path, flags, function(err, filename, fs_event)
    -- vim.print(filename)
    -- vim.print("EVENT:")
    if err then
      -- watcher:stop()
      return error("Error watching path: " .. err)
    end

    if not filename or filename == "." or filename == ".." or filename == "" then -- Ignore invalid filenames
      vim.print("edge case, check which one!!")
      return
    end

    local known_watcher_type = watcher.statTree[watcher.path] and watcher.statTree[watcher.path].type
    local filename_targets_watcher_path = (known_watcher_type == "directory")
      and (Path.basename(watcher.path) == filename)
    if filename_targets_watcher_path then
      vim.print("filename_targets_watcher_path diversion ", watcher.path)
      return
    end

    -- NOTE: Make so that this full_path setting is always relative to "./" removal
    local full_path
    if known_watcher_type == "file" then
      full_path = watcher.path
    elseif known_watcher_type == "link" then
      full_path = (Path.basename(watcher.path) == filename and watcher.path) or Path.join(watcher.path, filename) -- TODO: THIS IS NEW, does is create issues with unclearing
    else
      full_path = (filename_targets_watcher_path and watcher.path) or Path.join(watcher.path, filename)
      -- TODO: Maybe here I need to add known_watcher_type == "file" thing
    end
    -- vim.print("full_path is:", full_path, " for watcher type", known_watcher_type)

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
  -- vim.print("start_watcher runs for:", watcher.path)

  if watcher.status == "watching" then
    return error("can't run start_watcher for a watcher that is already watching")
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
      if watcher.handle == nil then -- NOTE: This is removed, this might cause bugs(?), double watch(?)
        watcher.handle = uv.new_fs_event()
      end

      -- NOTE: Here probably start_fs_event doesnt fire correctly
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

local function clear_redundant_child_watchers_from(parent_watcher, child_watchers)
  for index, watcher in ipairs(parent_watcher.child_watchers) do
    if List.index_of(child_watchers, watcher) then
      table.remove(parent_watcher.child_watchers, index)
    end
  end

  if parent_watcher.parent_watcher then
    clear_redundant_child_watchers_from(parent_watcher.parent_watcher, child_watchers)
  end
end

local function scope_filename_to_watcher_path(event_entry, watcher)
  -- if event_entry.filename ~= watcher.path and String.starts_with(event_entry.filename, watcher.path) then
  --   p("ZZZZZZZZZZZZZZZ:")
  --   p(event_entry.filename)
  --   return String.slice(event_entry.filename, #watcher.path + 2)
  -- end

  return event_entry.filename
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
        -- vim.print("CLOSING..", self.path, self.handle:getpath())
        uv.fs_event_stop(self.handle)
        self.status = "stopped"

        for _, child_path in pairs(self:get_watched_paths()) do
          self.statTree[child_path] = nil
        end
        self.statTree[self.path] = nil -- NOTE: Probably needed

        -- NOTE: calls each time, should call once(?)
        for _, child in pairs(self.child_watchers) do
          child:stop()
        end
      end

      if self.recovery_watcher then
        self.recovery_watcher:stop()
      end
    end,

    unwatch = function(self)
      self:stop()

      local target_watchers = { self }
      for index, child_watcher in ipairs(self.child_watchers) do
        table.insert(target_watchers, child_watcher)
        child_watcher:stop()

        List.delete(WATCHERS[child_watcher.path], child_watcher)
        vim.print("child_watcher.path is:", child_watcher.path)
        Object.remove(self.statTree, child_watcher.path) -- NOTE: Essential for regeneration on replace or restart

        table.remove(self.child_watchers, index)
      end

      if self.parent_watcher then
        clear_redundant_child_watchers_from(self.parent_watcher, target_watchers)
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
    "REGISTERING TOP-LEVEL recovery WATCHER: full_path is: ",
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

  outermost_parent_watcher:stop() -- NOTE: This is needed
  outermost_parent_watcher.recovery_watcher = create_watcher(parent_dir, { recursive = false }) -- NOTE: what if the parent watcher already exists?, it takes some time to actually create the listener
  outermost_parent_watcher.recovery_watcher:add_callback(function(event, event_path, stat)
    vim.print("RECOVERY ADD CALL", event, event_path)

    if (event == EVENTS.ADD or event == EVENTS.ADD_DIR) and event_path == lost_watcher_path then
      uv.fs_stat(lost_watcher_path, function(_, stat)
        outermost_parent_watcher:restart() -- NOTE: This doesnt immediately turn the watcher from "stopped" to "watching"
        outermost_parent_watcher.recovery_watcher:unwatch() -- TODO: Should this be stop instead?
        outermost_parent_watcher.recovery_watcher = nil

        -- TODO: This should happen after watcher being ready
        for _, cb in ipairs(outermost_parent_watcher.callbacks) do
          cb(event, lost_watcher_path, stat)
        end
      end)
    end
  end)
end

-- Updated function to handle unlink and add events
handle_fs_event = function(watcher, options, full_path, current_stat, fs_event)
  -- TODO: maybe add convert-to-relative path here? ALSO NEEDS WATCHERS[path] fix maybe?

  -- NOTE: is this a problem with watcher.statTree registration(?) ** statTree and other full_path dependent paths are wrong!
  -- if String.starts_with(full_path, "./") then
  --   full_path = String.slice(full_path, 3) -- TODO: Move this to start_fs_event for performance reasons
  -- end

  -- local filename = (String.starts_with(full_path, watcher.path) and String.slice(full_path, #watcher.path + 2))
  local filename = full_path
  -- local full_path_had_relative_handler = (full_path ~= watcher.path) and String.starts_with(full_path, watcher.path)
  -- if full_path_had_relative_handler then
  --   filename = String.slice(full_path, #watcher.path + 2)
  -- end

  -- vim.print("WATHCER PATH:", watcher.path)
  -- vim.print("full_path: ", full_path)
  local old_entry = watcher.statTree[full_path] -- TODO: This exists(?)

  local event_entry = { filename = filename, fs_event = fs_event }
  -- p(old_entry)
  -- p(current_stat)

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
        create_watcher(full_path, options, watcher) -- TODO: !!! This is sometimes watcher, sometimes parent_watcher?
      end
    end
  elseif not current_stat then
    vim.print("full_path ISSSSSSSSSS:", full_path)
    event_entry.event = (old_entry.type == "directory" and EVENTS.UNLINK_DIR) or EVENTS.UNLINK
    watcher.statTree[full_path] = nil

    if (old_entry.type == "directory") and options.recursive then
      -- vim.print("CLEAAARING: full_path is: ", full_path, " watcher.path is: ", watcher.path)
      local target_watcher = List.find(watcher.child_watchers, function(child_watcher)
        return child_watcher.path == full_path
      end)

      target_watcher:unwatch()
    end

    if watcher.parent_watcher == nil and full_path == watcher.path then -- NOTE: maybe this causes problems
      watcher:unwatch()
      -- TODO: add here unwatch maybe
      register_recovery_watcher_for(watcher, full_path, options) -- NOTE: This doesnt remove the removed folder watcher, which shouldnt fire multiple events?
      -- else
    end
    -- vim.print("unlink/unlink_dir | WHAT I WANTED HAPPENS:")
    -- vim.print("full_path", full_path)
    -- vim.print("watcher.path", watcher.path)
    -- p(watcher)
    -- end
  elseif current_stat.mtime ~= old_entry.stat.mtime then
    if current_stat.ino ~= old_entry.stat.ino then
      event_entry.rename = true
    end

    -- vim.print("CURRENT_STAT:")
    -- p(current_stat)
    -- p("OLD_ENTRY:")
    -- p(old_entry)

    event_entry.event = EVENTS.CHANGE
    watcher.statTree[full_path] = { type = current_stat.type, stat = current_stat }
  else
    vim.print("RARE CASE, does it ever happen?")
    return
  end

  for _, cb in ipairs(watcher.callbacks) do
    local target_filename = scope_filename_to_watcher_path(event_entry, watcher)

    cb(event_entry.event, target_filename, current_stat)
  end

  if event_entry.rename then
    watcher:unwatch()

    local new_watcher = create_watcher(watcher.path, options, watcher.parent_watcher) -- NOTE: Check if this is working correctly
    if #new_watcher.callbacks == 0 then
      for _, callback in pairs(watcher.callbacks) do
        new_watcher:add_callback(callback)
      end
    end
    vim.print("RENAME WATCHER CALLED:")
    vim.print(watcher.handle:getpath())

    p(new_watcher)
  end
end

local function watch(path, options, callback)
  if String.starts_with(path, "./") or path == "." then
    path = vim.uv.cwd() .. String.slice(path, 2)
  end

  p("<<<<<<<<<<<<<<<<<<<<<<")
  p(path)

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

-- FS.watch
local function FS_watch(input_paths, options, callback)
  local paths = type(input_paths) == "table" and input_paths or { input_paths }
  local watchers = {}
  for _, path in ipairs(paths) do
    table.insert(watchers, watch(path, options, callback))
  end

  if #watchers == 1 then
    return watchers[1]
  end

  watchers.callbacks = {}
  watchers.stop = function(self)
    for _, watcher in ipairs(self) do
      watcher:stop()
    end
  end
  watchers.add_callback = function(self, cb)
    table.insert(self.callbacks, callback)

    for _, watcher in ipairs(watchers) do
      watcher:add_callback(cb)
    end
  end

  return watchers
end

-- FS.unwatch
local function FS_unwatch(watcher)
  return watcher:unwatch()
end

return {
  watch = FS_watch,
  unwatch = FS_unwatch,
}
