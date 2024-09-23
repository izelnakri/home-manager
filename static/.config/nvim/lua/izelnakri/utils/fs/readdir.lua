local Path = require("izelnakri.utils.path")

local function recursive_readdir_sync(current_path, options, current_depth)
  options.result = options.result or {}
  current_depth = current_depth or 0

  local scandir, err = vim.uv.fs_scandir(current_path)
  if not scandir then
    return nil, "Failed to open directory: " .. current_path
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

local function recursive_readdir_async(current_path, options, current_depth, callback)
  options.result = options.result or {}
  current_depth = current_depth or 0

  vim.uv.fs_scandir(current_path, function(err, scandir)
    if err then
      return callback(nil, "Failed to open directory: " .. current_path)
    end

    local function next_entry()
      vim.uv.fs_scandir_next(scandir, function(err, name, type_)
        if err then
          return callback(nil, "Error reading directory: " .. current_path)
        end

        if not name then
          local filtered_results = {}
          for _, entry in ipairs(options.result) do
            if options.filter(entry.type, entry.name) then
              table.insert(filtered_results, entry)
            end
          end
          return callback(filtered_results)
        end

        local entry_path = Path.join(current_path, name)

        table.insert(options.result, {
          name = entry_path,
          type = type_,
        })

        if type_ == "directory" and options.recursive and (not options.depth or current_depth < options.depth) then
          recursive_readdir_async(entry_path, options, current_depth + 1, function()
            next_entry()
          end)
        else
          next_entry()
        end
      end)
    end

    next_entry()
  end)
end

---@param path_or_dir string | userdata Path or Dir entry from vim.uv.fs_opendir
---@param options { recursive: boolean, max_entry_size?: number, depth: number, filter: fun(type, path) }
---@param callback? function(err?: string, entries?: { name: string, type: string })
return function(path_or_dir, options, callback)
  options = options or {}
  options.recursive = options.recursive or false
  options.depth = options.depth or nil
  options.filter = options.filter or function()
    return true
  end

  if callback then
    -- TODO: Check if the path exists
    recursive_readdir_async(path_or_dir, options, callback)
  else
    local stat = vim.uv.fs_stat(path_or_dir)
    if not stat then
      return error("Path does not exist: " .. path_or_dir)
    end

    return recursive_readdir_sync(path_or_dir, options, 0)
  end
end

-- local VERY_BIG_NUMBER = 1000000 -- NOTE: Max size in my computer
--
-- ---@param path_or_dir string | userdata Path or Dir entry from vim.uv.fs_opendir
-- ---@param options { recursive: boolean, max_entry_size?: number, depth: number, filter: fun(type, path), result?: {}, prefix?: string }
-- ---@param callback? function(err?: string, entries?: { name: string, type: string })
-- local function recursive_readdir(path, options, callback, current_depth)
--   options.result = options.result or {}
--   options.prefix = options.prefix or ""
--   current_depth = current_depth or 0
--
--   local target = (options.prefix == "" and path) or options.prefix
--   local target_dir = (String.ends_with(target, "/") and String.slice(target, 0, -1)) or target
--
--   if callback then
--     local pending_ops = 1
--
--     local function check_done()
--       pending_ops = pending_ops - 1
--       if pending_ops == 0 then
--         return callback(nil, options.result)
--       end
--     end
--
--     local function process_directory(target_dir, prefix, current_depth, options)
--       if current_depth <= options.depth then
--         pending_ops = pending_ops + 1
--
--         vim.uv.fs_opendir(target_dir, function(err, dir)
--           if err then
--             return callback(err)
--           end
--
--           local function read_next_batch() -- Added function to read multiple batches
--             vim.uv.fs_readdir(dir, function(err, entries)
--               if err then
--                 return callback(err)
--               end
--
--               if not entries or #entries == 0 then -- Stop if no more entries
--                 vim.uv.fs_closedir(dir, function(err)
--                   if err then
--                     return callback(err)
--                   end
--                   check_done()
--                 end)
--                 return
--               end
--
--               for _, entry in pairs(entries) do
--                 local entry_path = target_dir .. entry.name
--
--                 if options.filter(entry.type, entry_path) then
--                   table.insert(options.result, {
--                     name = Path.join(List.slice(Path.split(entry_path), 2)),
--                     type = entry.type,
--                   })
--
--                   if entry.type == "directory" then
--                     process_directory(
--                       target_dir .. "/" .. entry.name .. "/",
--                       prefix .. entry.name .. "/",
--                       current_depth + 1,
--                       options
--                     )
--                   end
--                 end
--               end
--
--               read_next_batch() -- Continue reading until all entries are consumed
--             end)
--           end
--
--           read_next_batch() -- Start reading the first batch
--         end, VERY_BIG_NUMBER)
--       end
--     end
--
--     process_directory(target_dir, options.prefix, current_depth, options)
--     return check_done()
--   end
--
--   -- Synchronous version
--   if current_depth <= options.depth then
--     local dir = vim.uv.fs_opendir(target_dir, nil, VERY_BIG_NUMBER)
--     local entries = {} -- Collect entries in a loop
--
--     repeat
--       local batch = vim.uv.fs_readdir(dir) -- Read in batches
--       if batch then
--         for _, entry in pairs(batch) do
--           local entry_path = Path.join(target_dir, entry.name)
--           if options.filter(entry.type, entry_path) then
--             table.insert(options.result, {
--               name = Path.join(List.slice(Path.split(entry_path), 2)),
--               type = entry.type,
--             })
--           end
--
--           if entry.type == "directory" then
--             options.prefix = target_dir .. "/" .. entry.name .. "/"
--             recursive_readdir(entry.name, options, callback, current_depth + 1)
--           end
--         end
--       end
--     until not batch -- Continue until all batches are consumed
--
--     vim.uv.fs_closedir(dir)
--   end
--
--   return options.result
-- end
--
-- ---@param path_or_dir string | userdata Path or Dir entry from vim.uv.fs_opendir
-- ---@param options? { recursive?: boolean, max_entry_size?: number, depth?: number, filter?: fun(type, path) }
-- ---@param callback? function(err?: string, entries?: { name: string, type: string })
-- return function(path_or_dir, options, callback)
--   if type(options) == "function" then
--     callback = options
--     options = {}
--   end
--
--   options = options or {}
--   options.recursive = options.recursive or not not options.depth
--   -- vim.print("is recursive?")
--   -- vim.print(options.recursive)
--
--   options.filter = options.filter or function()
--     return true
--   end
--
--   if options.recursive then
--     options.depth = options.depth or math.huge
--
--     if type(path_or_dir) ~= "string" then
--       return error(
--         "FS.readdir(path_or_dir) can only read paths recursively, it can't read already open directory streams!"
--       )
--     end
--
--     return recursive_readdir(path_or_dir, options, callback)
--   end
--
--   if callback then
--     if type(path_or_dir) == "string" then
--       return vim.uv.fs_opendir(path_or_dir, function(err, dir)
--         if err then
--           vim.uv.fs_closedir(dir, function() end)
--           return callback(err)
--         end
--
--         local function read_next_batch() -- Added function to read multiple batches in async mode
--           vim.uv.fs_readdir(dir, function(err, entries)
--             if err then
--               return callback(err)
--             end
--
--             if not entries or #entries == 0 then
--               return vim.uv.fs_closedir(dir, function()
--                 return callback(nil, options.result)
--               end)
--             end
--
--             for _, entry in pairs(entries) do
--               if options.filter(entry.type, entry.name) then
--                 table.insert(options.result, entry)
--               end
--             end
--
--             read_next_batch() -- Continue reading the next batch
--           end)
--         end
--
--         read_next_batch()
--       end, options.max_entry_size or VERY_BIG_NUMBER)
--     end
--
--     local function read_next_batch() -- Handle case where dir entry is passed
--       vim.uv.fs_readdir(path_or_dir, function(err, entries)
--         if err then
--           return callback(err)
--         end
--
--         if not entries or #entries == 0 then
--           return callback(nil, options.result)
--         end
--
--         for _, entry in pairs(entries) do
--           if options.filter(entry.type, entry.name) then
--             table.insert(options.result, entry)
--           end
--         end
--
--         read_next_batch()
--       end)
--     end
--
--     read_next_batch() -- Start reading the first batch
--     return
--   end
--
--   local target_dir = (
--     type(path_or_dir) == "string" and vim.uv.fs_opendir(path_or_dir, nil, options.max_entry_size or VERY_BIG_NUMBER)
--   ) or path_or_dir
--
--   local entries = {}
--   repeat
--     local batch = vim.uv.fs_readdir(target_dir) -- Read in batches
--     if batch then
--       for _, entry in pairs(batch) do
--         if options.filter(entry.type, entry.name) then
--           table.insert(entries, entry)
--         end
--       end
--     end
--   until not batch -- Continue reading until all entries are consumed
--
--   vim.uv.fs_closedir(target_dir)
--   return entries
-- end
--  I have these tests:
-- local FS = require("izelnakri.utils.fs")
-- local Path = require("izelnakri.utils.path")
-- local uv = vim.uv or vim.loop
--
-- -- Helper functions for tests
-- local function create_temp_dir()
--   local tmp_dir = Path.join(os.tmpname())
--   -- os.tmpname() may create a file; ensure it's a directory
--   os.remove(tmp_dir)
--   local success, err = FS.mkdir(tmp_dir)
--   assert.is_true(success, "Failed to create temp directory: " .. tostring(err))
--   return tmp_dir
-- end
--
-- local function create_file(file_path, content)
--   return FS.writefile(file_path, content or "test")
-- end
--
-- local function create_symlink(target, link_path)
--   local success, err = uv.fs_symlink(target, link_path)
--   assert.is_true(success, "Failed to create symlink: " .. tostring(err))
-- end
--
-- local function directory_exists(dir_path)
--   local stat = uv.fs_stat(dir_path)
--   return (stat and stat.type == "directory") or false
-- end
--
-- local function file_exists(file_path)
--   local stat = uv.fs_stat(file_path)
--   return (stat and stat.type == "file") or false
-- end
--
-- local function symlink_exists(link_path)
--   local stat = uv.fs_stat(link_path)
--   return (stat and stat.type == "link") or false
-- end
--
-- local function delete_path(path)
--   local stat = uv.fs_stat(path)
--   if not stat then
--     return true
--   end
--   if stat.type == "file" or stat.type == "link" then
--     return uv.fs_unlink(path) == 0
--   elseif stat.type == "directory" then
--     return uv.fs_rmdir(path) == 0
--   else
--     return false
--   end
-- end
--
-- describe("FS.readdir", function()
--   local temp_dir
--
--   before_each(function()
--     temp_dir = create_temp_dir()
--   end)
--
--   after_each(function()
--     -- Cleanup: Remove temp_dir if it still exists
--     local function cleanup_dir(dir)
--       local scan = uv.fs_scandir(dir)
--       if scan then
--         while true do
--           local name, type_ = uv.fs_scandir_next(scan)
--           if not name then
--             break
--           end
--           if name ~= "." and name ~= ".." then
--             local full_path = Path.join(dir, name)
--             if type_ == "directory" then
--               cleanup_dir(full_path)
--               uv.fs_rmdir(full_path)
--             elseif type_ == "file" or type_ == "link" then
--               uv.fs_unlink(full_path)
--             end
--           end
--         end
--         uv.fs_rmdir(dir)
--       end
--     end
--
--     cleanup_dir(temp_dir)
--   end)
--
--   -- NOTE: check "/dir" or dir entries string in node.js and deno to verify -> check from the noted test
--   -- NOTE: fix max_entry size
--   -- NOTE: max_entry_size combi test?
--   -- NOTE: fs_readdir fails | entries on sync, on async: err(nil|string), entries|nil
--   describe("FS.readdir (sync)", function()
--     it("should read a directory with only files", function()
--       local file1 = Path.join(temp_dir, "file1.txt")
--       local file2 = Path.join(temp_dir, "file2.txt")
--       create_file(file1)
--       create_file(file2)
--
--       local entries, error = FS.readdir(temp_dir)
--
--       assert.is_nil(error)
--       table.sort(entries, function(a, b)
--         return a.name < b.name
--       end)
--       assert.are.same({
--         { name = "file1.txt", type = "file" },
--         { name = "file2.txt", type = "file" },
--       }, entries)
--     end)
--
--     it("should read a directory with only subdirectories", function()
--       local sub_dir1 = Path.join(temp_dir, "sub_dir1")
--       local sub_dir2 = Path.join(temp_dir, "sub_dir2")
--       FS.mkdir(sub_dir1)
--       FS.mkdir(sub_dir2)
--
--       local entries = FS.readdir(temp_dir)
--       table.sort(entries, function(a, b)
--         return a.name < b.name
--       end)
--       assert.are.same({
--         { name = "sub_dir1", type = "directory" },
--         { name = "sub_dir2", type = "directory" },
--       }, entries)
--     end)
--
--     it("should read a directory with mixed files and subdirectories", function()
--       local sub_dir = Path.join(temp_dir, "sub_dir")
--       FS.mkdir(sub_dir)
--       local file1 = Path.join(temp_dir, "file1.txt")
--       local file2 = Path.join(sub_dir, "file2.txt")
--       create_file(file1)
--       create_file(file2)
--
--       local entries = FS.readdir(temp_dir)
--       table.sort(entries, function(a, b)
--         return a.name < b.name
--       end)
--       assert.are.same({
--         { name = "file1.txt", type = "file" },
--         { name = "sub_dir", type = "directory" },
--       }, entries)
--     end)
--
--     it("should handle directories with similar prefixes", function()
--       local dir1 = Path.join(temp_dir, "dir")
--       local dir2 = Path.join(temp_dir, "directory")
--       FS.mkdir(dir1)
--       FS.mkdir(dir2)
--
--       local entries = FS.readdir(temp_dir)
--       table.sort(entries, function(a, b)
--         return a.name < b.name
--       end)
--       assert.are.same({
--         { name = "dir", type = "directory" },
--         { name = "directory", type = "directory" },
--       }, entries)
--     end)
--
--     it("should read a directory recursively", function()
--       local sub_dir1 = Path.join(temp_dir, "sub_dir1")
--       local sub_dir2 = Path.join(temp_dir, "sub_dir2")
--       local sub_dir2_sub_dir = Path.join(sub_dir2, "sub_dir")
--       FS.mkdir(sub_dir1)
--       FS.mkdir(sub_dir2)
--       FS.mkdir(sub_dir2_sub_dir)
--       local file1 = Path.join(temp_dir, "file1.txt")
--       local file2 = Path.join(sub_dir1, "file2.txt")
--       local file3 = Path.join(sub_dir2, "file3.txt")
--       local file4 = Path.join(sub_dir2, "file4.txt")
--       local file5 = Path.join(sub_dir2_sub_dir, "file5.txt")
--
--       create_file(file1)
--       create_file(file2)
--       create_file(file3)
--       create_file(file4)
--       create_file(file5)
--
--       local entries = FS.readdir(temp_dir, { recursive = true })
--       table.sort(entries, function(a, b)
--         return a.name < b.name
--       end)
--
--       local temp_dir_path = String.slice(temp_dir, 2)
--       assert.are.same({
--         { name = temp_dir_path .. "/file1.txt", type = "file" },
--         { name = temp_dir_path .. "/sub_dir1", type = "directory" },
--         { name = temp_dir_path .. "/sub_dir1/file2.txt", type = "file" },
--         { name = temp_dir_path .. "/sub_dir2", type = "directory" },
--         { name = temp_dir_path .. "/sub_dir2/file3.txt", type = "file" },
--         { name = temp_dir_path .. "/sub_dir2/file4.txt", type = "file" },
--         { name = temp_dir_path .. "/sub_dir2/sub_dir", type = "directory" },
--         { name = temp_dir_path .. "/sub_dir2/sub_dir/file5.txt", type = "file" },
--       }, entries)
--     end)
--
--     it("should apply a filter function correctly", function()
--       local sub_dir = Path.join(temp_dir, "sub_dir_filter")
--       FS.mkdir(sub_dir)
--       local file1 = Path.join(temp_dir, "file1_filter.txt")
--       local file2 = Path.join(sub_dir, "file2_filter.log")
--       create_file(file1)
--       create_file(file2)
--
--       local entries = FS.readdir(temp_dir, {
--         filter = function(type_, path)
--           return type_ == "file" and Path.extname(path) == "txt"
--         end,
--       })
--
--       assert.are.same({
--         { name = "file1_filter.txt", type = "file" },
--       }, entries)
--     end)
--
--     it("should apply a filter function correctly with recursion", function()
--       local sub_dir1 = Path.join(temp_dir, "sub_dir1")
--       local sub_dir2 = Path.join(temp_dir, "sub_dir2")
--       local sub_dir2_sub_dir = Path.join(sub_dir2, "sub_dir")
--       FS.mkdir(sub_dir1)
--       FS.mkdir(sub_dir2)
--       FS.mkdir(sub_dir2_sub_dir)
--       local file1 = Path.join(temp_dir, "file1.txt")
--       local file2 = Path.join(sub_dir1, "file2.txt")
--       local file3 = Path.join(sub_dir2, "file3.txt")
--       local file4 = Path.join(sub_dir2, "file4.txt")
--       local file5 = Path.join(sub_dir2_sub_dir, "file5.txt")
--
--       create_file(file1)
--       create_file(file2)
--       create_file(file3)
--       create_file(file4)
--       create_file(file5)
--
--       local entries = FS.readdir(temp_dir, {
--         recursive = true,
--         filter = function(type_, path)
--           return type_ == "file" and String.includes(path, "sub_dir2")
--         end,
--       })
--       table.sort(entries, function(a, b)
--         return a.name < b.name
--       end)
--
--       local temp_dir_path = String.slice(temp_dir, 2)
--       assert.are.same({
--         { name = temp_dir_path .. "/sub_dir2/file3.txt", type = "file" },
--         { name = temp_dir_path .. "/sub_dir2/file4.txt", type = "file" },
--         { name = temp_dir_path .. "/sub_dir2/sub_dir/file5.txt", type = "file" },
--       }, entries)
--     end)
--
--     -- TODO: This test case is buggy:
--     it("should respect the max_entry_size option", function()
--       local sub_dir1 = Path.join(temp_dir, "sub_dir1")
--       local sub_dir2 = Path.join(temp_dir, "sub_dir2")
--       local sub_dir2_sub_dir = Path.join(sub_dir2, "sub_dir")
--       FS.mkdir(sub_dir1)
--       FS.mkdir(sub_dir2)
--       FS.mkdir(sub_dir2_sub_dir)
--
--       local files = {}
--       for i = 1, 10 do
--         local file = Path.join(temp_dir, "file" .. i .. ".txt")
--         create_file(file)
--         table.insert(files, { name = "file" .. i .. ".txt", type = "file" })
--       end
--
--       local file1 = Path.join(temp_dir, "file1.txt")
--       local file2 = Path.join(sub_dir1, "file2.txt")
--       local file3 = Path.join(sub_dir2, "file3.txt")
--       local file4 = Path.join(sub_dir2, "file4.txt")
--       local file5 = Path.join(sub_dir2_sub_dir, "file5.txt")
--
--       create_file(file1)
--       create_file(file2)
--       create_file(file3)
--       create_file(file4)
--       create_file(file5)
--
--       -- -- local temp_dir_path = String.slice(temp_dir, 2)
--       -- -- assert.are.same({
--       -- --   { name = temp_dir_path .. "/sub_dir2/file3.txt", type = "file" },
--       -- --   { name = temp_dir_path .. "/sub_dir2/file4.txt", type = "file" },
--       -- --   { name = temp_dir_path .. "/sub_dir2/sub_dir/file5.txt", type = "file" },
--       -- -- }, entries)
--       --
--       -- local entries = FS.readdir(temp_dir, { max_entry_size = 5 })
--       -- assert.are.equal(5, #entries, "Returned entries should be limited to max_entry_size")
--       --
--       -- -- local entries = FS.readdir(temp_dir, { recursive = true, max_entry_size = 6 })
--       -- -- assert.are.equal(6, #entries, "Returned entries should be limited to max_entry_size")
--       -- --
--       -- -- local entries = FS.readdir(temp_dir, {
--       -- --   recursive = true,
--       -- --   max_entry_size = 2,
--       -- --   filter = function(type_, path)
--       -- --     return type_ == "file" and String.includes(path, "sub_dir2")
--       -- --   end,
--       -- -- })
--       -- -- assert.are.equal(5, #entries, "Returned entries should be limited to max_entry_size")
--     end)
--
--     it("should limit recursion depth correctly", function()
--       local dir_a = Path.join(temp_dir, "a")
--       local dir_b = Path.join(dir_a, "b")
--       local dir_c = Path.join(dir_b, "c")
--       FS.mkdir(dir_a)
--       create_file(Path.join(dir_a, "file_a.txt"))
--       FS.mkdir(dir_b)
--       FS.mkdir(dir_c)
--       create_file(Path.join(dir_c, "file_c.txt"))
--
--       local entries = FS.readdir(temp_dir, { recursive = true, depth = 1 })
--       table.sort(entries, function(a, b)
--         return a.name < b.name
--       end)
--
--       local temp_dir_path = String.slice(temp_dir, 2)
--       assert.are.same({
--         { name = temp_dir_path .. "/a", type = "directory" },
--         { name = temp_dir_path .. "/a/b", type = "directory" },
--         { name = temp_dir_path .. "/a/file_a.txt", type = "file" },
--       }, entries)
--     end)
--
--     it("should handle empty directories", function()
--       local empty_dir = Path.join(temp_dir, "empty_dir")
--       FS.mkdir(empty_dir)
--
--       local entries, error = FS.readdir(empty_dir, options)
--       assert.are.same({}, entries)
--     end)
--
--     -- NOTE: Improve error message of this test in future
--     it("should return an error for non-existent paths", function()
--       local fake_path = Path.join(temp_dir, "non_existent")
--       assert.has_errors(function()
--         FS.readdir(fake_path)
--       end)
--     end)
--
--     it("should handle symlinks correctly", function()
--       local real_dir = Path.join(temp_dir, "real_dir")
--       FS.mkdir(real_dir)
--       create_symlink(real_dir, Path.join(temp_dir, "symlink_dir"))
--       create_file(Path.join(real_dir, "file_in_real_dir.txt"))
--
--       local entries = FS.readdir(temp_dir, {
--         recursive = true,
--         depth = 10,
--       })
--       local temp_dir_path = String.slice(temp_dir, 2)
--       table.sort(entries, function(a, b)
--         return a.name < b.name
--       end)
--       assert.are.same({
--         { name = temp_dir_path .. "/real_dir", type = "directory" },
--         { name = temp_dir_path .. "/real_dir/file_in_real_dir.txt", type = "file" },
--         { name = temp_dir_path .. "/symlink_dir", type = "link" },
--       }, entries)
--       local entries = FS.readdir(temp_dir)
--       table.sort(entries, function(a, b)
--         return a.name < b.name
--       end)
--       assert.are.same({
--         { name = "real_dir", type = "directory" },
--         { name = "symlink_dir", type = "link" },
--       }, entries)
--     end)
--   end) end)

-- local VERY_BIG_NUMBER = 1000000 -- NOTE: Max size in my computer
--
-- ---@param path_or_dir string | userdata Path or Dir entry from vim.uv.fs_opendir
-- ---@param options { recursive: boolean, max_entry_size?: number, depth: number, filter: fun(type, path), result?: {}, prefix?: string }
-- ---@param callback? function(err?: string, entries?: { name: string, type: string })
-- local function recursive_readdir(path, options, callback, current_depth)
--   options.result = options.result or {}
--   options.prefix = options.prefix or ""
--   current_depth = current_depth or 0
--
--   local target = (options.prefix == "" and path) or options.prefix
--   local target_dir = (String.ends_with(target, "/") and String.slice(target, 0, -1)) or target
--
--   if callback then
--     local pending_ops = 1
--
--     local function check_done()
--       pending_ops = pending_ops - 1
--       if pending_ops == 0 then
--         return callback(nil, options.result)
--       end
--     end
--
--     local function process_directory(target_dir, prefix, current_depth, options)
--       if current_depth <= options.depth then
--         pending_ops = pending_ops + 1
--
--         vim.uv.fs_opendir(target_dir, function(err, dir)
--           if err then
--             return callback(err)
--           end
--
--           vim.uv.fs_readdir(dir, function(err, entries)
--             if err then
--               return callback(err)
--             end
--
--             for _, entry in pairs(entries or {}) do
--               local entry_path = target_dir .. entry.name
--
--               if options.filter(entry.type, entry_path) then
--                 table.insert(options.result, {
--                   name = Path.join(List.slice(Path.split(entry_path), 2)),
--                   type = entry.type,
--                 })
--
--                 if entry.type == "directory" then
--                   process_directory(
--                     target_dir .. "/" .. entry.name .. "/",
--                     prefix .. entry.name .. "/",
--                     current_depth + 1,
--                     options
--                   )
--                 end
--               end
--             end
--
--             vim.uv.fs_closedir(dir, function(err)
--               if err then
--                 return callback(err)
--               end
--
--               check_done()
--             end)
--           end)
--         end, VERY_BIG_NUMBER)
--       end
--     end
--
--     process_directory(target_dir, options.prefix, current_depth, options)
--
--     return check_done()
--   end
--
--   if current_depth <= options.depth then
--     local dir = vim.uv.fs_opendir(target_dir, nil, VERY_BIG_NUMBER)
--     for _, entry in pairs(vim.uv.fs_readdir(dir) or {}) do
--       local entry_path = Path.join(target_dir, entry.name)
--       if options.filter(entry.type, entry_path) then
--         table.insert(options.result, {
--           name = Path.join(List.slice(Path.split(entry_path), 2)),
--           type = entry.type,
--         })
--       end
--
--       if entry.type == "directory" then
--         options.prefix = target_dir .. "/" .. entry.name .. "/"
--
--         recursive_readdir(entry.name, options, callback, current_depth + 1)
--       end
--     end
--
--     vim.uv.fs_closedir(dir)
--   end
--
--   return options.result
-- end
--
-- ---@param path_or_dir string | userdata Path or Dir entry from vim.uv.fs_opendir
-- ---@param options? { recursive?: boolean, max_entry_size?: number, depth?: number, filter?: fun(type, path) }
-- ---@param callback? function(err?: string, entries?: { name: string, type: string })
-- return function(path_or_dir, options, callback)
--   if type(options) == "function" then
--     callback = options
--     options = {}
--   end
--
--   options = options or {}
--   options.recursive = options.recursive or not not options.depth
--   vim.print("is recursive?")
--   vim.print(options.recursive)
--
--   options.filter = options.filter or function()
--     return true
--   end
--
--   if options.recursive then
--     options.depth = options.depth or math.huge
--
--     if type(path_or_dir) ~= "string" then
--       return error(
--         "FS.readdir(path_or_dir) can only read paths recursively, it can't read already open directory streams!"
--       )
--     end
--
--     return recursive_readdir(path_or_dir, options, callback)
--   end
--
--   if callback then
--     if type(path_or_dir) == "string" then
--       return vim.uv.fs_opendir(path_or_dir, function(err, dir)
--         if err then
--           vim.uv.fs_closedir(dir, function() end)
--           return callback(err)
--         end
--
--         return vim.uv.fs_readdir(dir, function(err, entries)
--           return callback(
--             err,
--             List.filter(entries or {}, function(entry)
--               return filter_func(entry.type, path_or_dir .. entry.name)
--             end)
--           )
--         end)
--       end, options.max_entry_size or VERY_BIG_NUMBER)
--     end
--
--     return vim.uv.fs_readdir(path_or_dir, function(err, entries)
--       return callback(
--         err,
--         List.filter(entries or {}, function(entry)
--           return options.filter(entry.type, entry.name)
--         end)
--       )
--     end)
--   end
--
--   local target_dir = (
--     type(path_or_dir) == "string" and vim.uv.fs_opendir(path_or_dir, nil, options.max_entry_size or VERY_BIG_NUMBER)
--   ) or path_or_dir
--
--   return List.filter(vim.uv.fs_readdir(target_dir) or {}, function(entry)
--     return options.filter(entry.type, entry.name)
--   end)
-- end
