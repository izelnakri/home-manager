-- NOTE: Maybe utilize uv.new_fs_poll instead of uv.new_fs_event, which has no flags but interval and different callback args: err, prev(stat), curr(stat)
-- TODO: Requires debouncing for CHANGE, inode is the primary key of a file/directory
-- NOTE: delete or add is always considered a rename, change that, also might need debouncing, hence new datatype and proper recursive watching
-- NOTE: fs_poll fixes multiple event problem, but it polls(?) | stat & recursive opts dont do shit
-- NOTE: Should I implement glob?(probably not, but could be useful for watch)
-- NOTE: Maybe add options.depth, options.use_polling, options.always_stat, interval | events: "addDir", "unlinkDir", "error", "ready", "raw", "add", "change", "unlink"

local uv = vim.uv
local watchers = {} -- Store active watchers globally

-- Helper function to stop a watcher
local function stop_watcher(watcher)
  if watcher.handle then
    uv.fs_event_stop(watcher.handle)
    watcher.handle:close()
    watcher.status = "stopped"
  end
end

-- Helper function to start a watcher
local function start_watcher(watcher, path, options)
  watcher.handle = uv.new_fs_event()

  -- NOTE: in future, tweak these maybe or allow from outside tweaking
  -- Determine flags based on options
  local flags = {
    watch_entry = true, -- Default not to watch individual entries
    stat = true, -- Default not to stat
    recursive = options.recursive or false, -- Set recursive flag based on options
  }

  -- Start watching the provided path using uv.fs_event_start
  uv.fs_event_start(watcher.handle, path, flags, function(err, filename, events)
    if err then
      watcher:stop() -- Stop on error
      error("Error watching path: " .. err)
    end

    -- NOTE: In future, maybe dont create an entry? This is for debug purposes
    -- Create an event entry for the callback
    local event_entry = { filename = filename, events = events }
    table.insert(watcher.entries, event_entry)

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
    allow_multiple = false, -- NOTE: in future this will make watchers be able to watch a watched/same directory
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

--- Watches a directory or file for changes with an optional recursive option.
--- @param path string: The path to watch.
--- @param options table|nil: Optional table with settings. { recursive = boolean }
--- @param callback function: A callback function triggered when an event occurs. The callback will receive (event(create | modify | remove) filename), maybe also directory type(if its not an extra syscall).
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

-- NOTE: maybe add watchers here
-- Export FS module
return {
  watchers = watchers,
  watch = FS_watch,
  unwatch = FS_unwatch,
}

-- Given the following FS.readdir module in neovim/lua: ```
--
--
--   and its relevant tests: ```
--
--
-- ``` I would like to build a FS.watch module with following signature: ```
--
-- ``` FS.watch should return a watcher object with following attributes: ```
--
-- ```` Test strategy: (read it from chatgpt)
--
--
-- --- Watches a directory or file for changes with an optional recursive option.
-- --- @param path string: The path to watch.
-- --- @param options table|nil: Optional table with settings. { recursive = boolean }
-- --- @param callback function: A callback function triggered when an event occurs. The callback will receive (event(create | modify | remove) filename), maybe also directory type(if its not an extra syscall).
-- --- @return watcher: The watcher handle that can be used for unwatching. { callbacks = function[], stop = function, restart = function, status = string, initialized_at = number, entries = entry[] }

-- file, directory, event names, allow stopping, error cases
--
--
-- Enhance the tests by checking for watch events(adding a new file, adding a new directory, changing existing file,
-- changing directory, removing file, removing directory), make unwatch case happen after events to see callbacks
-- dont get called and see if the paths truly unwatched. Write tests see what if 2 watches watch the same paths,
-- FS.unwatch should only unwatch one watcher while the other should be running. Thus should FS.unwatch accepts a
-- watcher instead of a path?
--
-- We should test that callback actually runs with a specific event and filename each time, ideally test should trigger
-- the event multiple times, there should be also other tests where we dont ever trigger the events, unwatch
-- the path and then see that event never gets called
--
-- FS.watch should receive an optional 2nd parameter options.recursive: boolean , adjust your module suggestion accordingly

-- local uv = vim.uv
--
-- local watchers = {}
--
-- --- Watches a directory or file for changes with an optional recursive option.
-- --- @param path string: The path to watch.
-- --- @param options table|nil: Optional table with settings. { recursive = boolean }
-- --- @param callback function: A callback function triggered when an event occurs. The callback will receive (event, filename).
-- --- @return watcher: The watcher handle that can be used for unwatching. { stop = function, restart = function, status = string, initialized_at = number, entries = entry[] }
-- return function(path, options, callback)
--   -- Default options to an empty table if nil
--   options = options or {}
--   local recursive = options.recursive or false
--
--   -- Ensure we have a table for watchers per path
--   if not watchers[path] then
--     watchers[path] = {}
--   end
--
--   -- Create a new watcher
--   local handle, err
--   handle, err = uv.new_fs_event()
--
--   if not handle then
--     error("Failed to create watcher: " .. err)
--   end
--
--   -- Start the watcher
--   local function on_event(err, filename, events)
--     if err then
--       print("Watcher error: " .. err)
--       return
--     end
--
--     -- Map uv events to simple ones
--     local event_type = nil
--     if events.change then
--       event_type = "change"
--     elseif events.rename then
--       event_type = "rename"
--     end
--
--     -- Call the callback with the event and filename
--     if filename then
--       callback(event_type, filename)
--     end
--   end
--
--   -- Start the watcher with the recursive option
--   local success, start_err = handle:start(path, { recursive = recursive }, on_event)
--   if not success then
--     error("Failed to start watching path: " .. start_err)
--   end
--
--   -- Store the watcher handle
--   table.insert(watchers[path], handle)
--   return handle
-- end

-- watch() in node: persistent? interval? and recursive returns strange awaitable iterator { eventType, filename }
-- it is watchFs(string | string[]), only has recursive returns as strange awaitable iterator FSWatcher.
-- in deno event its { kind: '', paths: []

-- Deno.FsEvent.kind is 'any' | 'access' | 'create' | 'modify' | 'remove' | 'other'
-- Deno.FsEvent.paths: string[]
-- Deno.FsEvent.flag? 'rescan' -> additional info on 'other' kind basically

-- TODO: poll watchers already stores the content in memory, checks hashes, does it stores only hashes
-- Path { mtime, hash, last_check(last hash) } -> uses some hashing algorithm(possible default rust HashMap hash, not configurable)
-- diff between folder and files

-- kind:
-- | "any"
-- | "access"
-- | "create"
-- | "modify"
-- | "remove"
-- | "other"
-- paths:
-- flag

-- local w = vim.uv.new_fs_event()
--
-- function watch_file(fullpath)
--   w:start(fullpath, {}, vim.schedule_wrap(function(...)
--     on_change(...)
--   end))
-- end
--
-- local function on_change(err, fname, status)
--   -- Do work...
--   vim.cmd("checktime")
--   -- Debounce: stop/start.
--   w:stop()
--   watch_file(fname)
-- end

-- Example: File-change detection                                    *watch-file*
--     1. Save this code to a file.
--     2. Execute it with ":luafile %".
--     3. Use ":Watch %" to watch any file.
--     4. Try editing the file from another text editor.
--     5. Observe that the file reloads in Nvim (because on_change() calls
--        |:checktime|). >lua
--
--     local w = vim.uv.new_fs_event()
--     local function on_change(err, fname, status)
--       -- Do work...
--       vim.api.nvim_command('checktime')
--       -- Debounce: stop/start.
--       w:stop()
--       watch_file(fname)
--     end
--     function watch_file(fname)
--       local fullpath = vim.api.nvim_call_function(
--         'fnamemodify', {fname, ':p'})
--       w:start(fullpath, {}, vim.schedule_wrap(function(...)
--         on_change(...) end))
--     end
--     vim.api.nvim_command(
--
--       "command! -nargs=1 Watch call luaeval('watch_file(_A)', expand('<args>'))")
-- <
