-- NOTE: Today it is not possible to watch a directory twice, make it possible
-- NOTE: Maybe in future implement atomic(swap file ignore) / ignore / ignoreInitials(tilde files, .dotfiles)
-- NOTE: Changing a folder and changing a file triggers CHANGE, no way to find rename, maybe in future implement rename instead of unlink_dir, add_dir
-- NOTE: on add dir, should I run through the folders and make all files and folders "add" and "add_dir"?

require("async.test")

local Path = require("izelnakri.utils.path")
local List = require("izelnakri.utils.list")
local wait = require("tests.utils.wait")

local uv = vim.uv
local FS = require("izelnakri.utils.fs")
local DEFAULT_TIMEOUT = 8000

local function create_temp_dir()
  local tmp_dir = Path.join(os.tmpname())
  os.remove(tmp_dir)
  assert(FS.mkdir(tmp_dir), "Failed to create temp directory")
  return tmp_dir
end

local function wait_event(watcher, expected_event, target_count, timeout)
  target_count = target_count or 1
  local should_pass = false
  local total_count = 0
  local last_event
  watcher:add_callback(function(event, path, stat)
    last_event = event
    if _G.DEBUG then
      vim.print("CALLBACK CALLED:")
      vim.print(vim.inspect(event), path)
      vim.print(vim.inspect(stat))
    end
    if event == expected_event then
      total_count = total_count + 1
      should_pass = true
    end
  end)
  vim.wait(timeout or DEFAULT_TIMEOUT, function()
    return should_pass
  end)
  if not should_pass then
    error("wait_event(watcher, " .. expected_event .. ") instead last event was: " .. tostring(last_event))
  elseif total_count < target_count then
    error(
      "wait_event(watcher, "
        .. expected_event
        .. ", "
        .. target_count
        .. " ) total_count was: "
        .. tostring(total_count)
    )
  end
  return should_pass
end

local function wait_for_call_count(spy, target_count, timeout)
  target_count = target_count or 1
  timeout = timeout or DEFAULT_TIMEOUT
  local should_pass = false
  vim.wait(timeout, function()
    should_pass = #spy.calls >= target_count
    return should_pass
  end)
  if not should_pass then
    vim.print(spy.calls)
    error("wait_for_call_count expected " .. target_count .. " instead had: " .. #spy.calls .. " calls")
  end

  return should_pass
end

local function wait_watcher_to_be_ready(watcher, timeout)
  local should_pass = false

  vim.wait(100) -- NOTE: Remove this readiness bug is fixed
  vim.wait(timeout or 10000, function()
    should_pass = watcher.status == "watching"
    return should_pass
  end)
  if not should_pass then
    error("wait_watcher_to_be_ready WASN'T READY, instead watcher.status is: " .. watcher.status)
  end

  return should_pass
end

local function get_fixture_path(temp_dir, target_path)
  return Path.join(temp_dir, target_path)
end

-- NOTE: maybe wait for event count**

describe("FS.watch", function()
  local temp_dir, watcher

  before_each(function()
    temp_dir = create_temp_dir()
  end)

  after_each(function()
    if watcher then
      watcher:stop()
    end

    -- Cleanup temp directory (implementation omitted for brevity)
  end)

  -- describe("watch a directory", function()
  --   it("should expose public API methods", function()
  --     watcher = FS.watch(temp_dir, { recursive = false })
  --     assert.is_function(watcher.add_callback, "Expected 'add_callback' function")
  --     assert.is_function(watcher.stop, "Expected 'stop' function")
  --     assert.is_function(watcher.restart, "Expected 'restart' function")
  --   end)
  --
  --   it("should emit `add` event when a file is created", function()
  --     local handler = spy.new()
  --     watcher = FS.watch(temp_dir, { recursive = true }, handler)
  --
  --     wait_watcher_to_be_ready(watcher)
  --
  --     local test_path = Path.join(temp_dir, "add.txt")
  --     FS.writefile(test_path, "test")
  --
  --     assert.is_true(wait_event(watcher, "add"), "Expected 'add' event for created file")
  --     assert.spy(handler).called(1) -- NOTE: This has to be once only
  --     assert.are.equal(handler.calls[1].vals[1], "add")
  --     assert.are.equal(handler.calls[1].vals[2], temp_dir .. "/add.txt")
  --   end)
  --
  --   it("should emit nine `add` events when nine files were added in one directory", function()
  --     local handler = spy.new()
  --     watcher = FS.watch(temp_dir, { recursive = false }, handler)
  --     wait_watcher_to_be_ready(watcher) -- NOTE: ESSENTIAL
  --
  --     local paths = {}
  --     for i = 1, 9 do
  --       table.insert(paths, Path.join(temp_dir, "add" .. i .. ".txt"))
  --     end
  --
  --     write_file(paths[1])
  --     write_file(paths[2])
  --     write_file(paths[3])
  --     write_file(paths[4])
  --     write_file(paths[5])
  --
  --     vim.wait(100)
  --
  --     write_file(paths[6])
  --     write_file(paths[7])
  --
  --     vim.wait(150)
  --
  --     write_file(paths[8])
  --     write_file(paths[9])
  --
  --     wait_for_call_count(handler, 4)
  --     vim.wait(1000)
  --     wait_for_call_count(handler, 9)
  --
  --     assert.spy(handler).called(9)
  --     for i = 1, #paths do
  --       assert.spy(handler).called_with("add", paths[i], match._)
  --     end
  --   end)
  --
  --   it("should emit thirtythree `add` events when thirtythree files were added in nine directories", function()
  --     local test1Path = get_fixture_path(temp_dir, "add1.txt")
  --     local testb1Path = get_fixture_path(temp_dir, "b/add1.txt")
  --     local testc1Path = get_fixture_path(temp_dir, "c/add1.txt")
  --     local testd1Path = get_fixture_path(temp_dir, "d/add1.txt")
  --     local teste1Path = get_fixture_path(temp_dir, "e/add1.txt")
  --     local testf1Path = get_fixture_path(temp_dir, "f/add1.txt")
  --     local testg1Path = get_fixture_path(temp_dir, "g/add1.txt")
  --     local testh1Path = get_fixture_path(temp_dir, "h/add1.txt")
  --     local testi1Path = get_fixture_path(temp_dir, "i/add1.txt")
  --     local test2Path = get_fixture_path(temp_dir, "add2.txt")
  --     local testb2Path = get_fixture_path(temp_dir, "b/add2.txt")
  --     local testc2Path = get_fixture_path(temp_dir, "c/add2.txt")
  --     local test3Path = get_fixture_path(temp_dir, "add3.txt")
  --     local testb3Path = get_fixture_path(temp_dir, "b/add3.txt")
  --     local testc3Path = get_fixture_path(temp_dir, "c/add3.txt")
  --     local test4Path = get_fixture_path(temp_dir, "add4.txt")
  --     local testb4Path = get_fixture_path(temp_dir, "b/add4.txt")
  --     local testc4Path = get_fixture_path(temp_dir, "c/add4.txt")
  --     local test5Path = get_fixture_path(temp_dir, "add5.txt")
  --     local testb5Path = get_fixture_path(temp_dir, "b/add5.txt")
  --     local testc5Path = get_fixture_path(temp_dir, "c/add5.txt")
  --     local test6Path = get_fixture_path(temp_dir, "add6.txt")
  --     local testb6Path = get_fixture_path(temp_dir, "b/add6.txt")
  --     local testc6Path = get_fixture_path(temp_dir, "c/add6.txt")
  --     local test7Path = get_fixture_path(temp_dir, "add7.txt")
  --     local testb7Path = get_fixture_path(temp_dir, "b/add7.txt")
  --     local testc7Path = get_fixture_path(temp_dir, "c/add7.txt")
  --     local test8Path = get_fixture_path(temp_dir, "add8.txt")
  --     local testb8Path = get_fixture_path(temp_dir, "b/add8.txt")
  --     local testc8Path = get_fixture_path(temp_dir, "c/add8.txt")
  --     local test9Path = get_fixture_path(temp_dir, "add9.txt")
  --     local testb9Path = get_fixture_path(temp_dir, "b/add9.txt")
  --     local testc9Path = get_fixture_path(temp_dir, "c/add9.txt")
  --
  --     FS.mkdir(get_fixture_path(temp_dir, "b"))
  --     FS.mkdir(get_fixture_path(temp_dir, "c"))
  --     FS.mkdir(get_fixture_path(temp_dir, "d"))
  --     FS.mkdir(get_fixture_path(temp_dir, "e"))
  --     FS.mkdir(get_fixture_path(temp_dir, "f"))
  --     FS.mkdir(get_fixture_path(temp_dir, "g"))
  --     FS.mkdir(get_fixture_path(temp_dir, "h"))
  --     FS.mkdir(get_fixture_path(temp_dir, "i"))
  --
  --     vim.wait(500)
  --
  --     local handler = spy.new()
  --     watcher = FS.watch(temp_dir, { recursive = true }, handler)
  --     wait_watcher_to_be_ready(watcher)
  --
  --     local filesToWrite = {
  --       test1Path,
  --       test2Path,
  --       test3Path,
  --       test4Path,
  --       test5Path,
  --       test6Path,
  --       test7Path,
  --       test8Path,
  --       test9Path,
  --       testb1Path,
  --       testb2Path,
  --       testb3Path,
  --       testb4Path,
  --       testb5Path,
  --       testb6Path,
  --       testb7Path,
  --       testb8Path,
  --       testb9Path,
  --       testc1Path,
  --       testc2Path,
  --       testc3Path,
  --       testc4Path,
  --       testc5Path,
  --       testc6Path,
  --       testc7Path,
  --       testc8Path,
  --       testc9Path,
  --       testd1Path,
  --       teste1Path,
  --       testf1Path,
  --       testg1Path,
  --       testh1Path,
  --       testi1Path,
  --     }
  --
  --     for _, fileToWrite in pairs(filesToWrite) do
  --       write_file(fileToWrite)
  --     end
  --
  --     wait_for_call_count(handler, #filesToWrite)
  --
  --     assert.spy(handler).called(33)
  --     assert.spy(handler).called_with("add", test1Path, match._)
  --     assert.spy(handler).called_with("add", test2Path, match._)
  --     assert.spy(handler).called_with("add", test3Path, match._)
  --     assert.spy(handler).called_with("add", test4Path, match._)
  --     assert.spy(handler).called_with("add", test5Path, match._)
  --     assert.spy(handler).called_with("add", test6Path, match._)
  --     assert.spy(handler).called_with("add", test7Path, match._)
  --     assert.spy(handler).called_with("add", test8Path, match._)
  --     assert.spy(handler).called_with("add", test9Path, match._)
  --     assert.spy(handler).called_with("add", testb1Path, match._)
  --     assert.spy(handler).called_with("add", testb2Path, match._)
  --     assert.spy(handler).called_with("add", testb3Path, match._)
  --     assert.spy(handler).called_with("add", testb4Path, match._)
  --     assert.spy(handler).called_with("add", testb5Path, match._)
  --     assert.spy(handler).called_with("add", testb6Path, match._)
  --     assert.spy(handler).called_with("add", testb7Path, match._)
  --     assert.spy(handler).called_with("add", testb8Path, match._)
  --     assert.spy(handler).called_with("add", testb9Path, match._)
  --     assert.spy(handler).called_with("add", testc1Path, match._)
  --     assert.spy(handler).called_with("add", testc2Path, match._)
  --     assert.spy(handler).called_with("add", testc3Path, match._)
  --     assert.spy(handler).called_with("add", testc4Path, match._)
  --     assert.spy(handler).called_with("add", testc5Path, match._)
  --     assert.spy(handler).called_with("add", testc6Path, match._)
  --     assert.spy(handler).called_with("add", testc7Path, match._)
  --     assert.spy(handler).called_with("add", testc8Path, match._)
  --     assert.spy(handler).called_with("add", testc9Path, match._)
  --     assert.spy(handler).called_with("add", testd1Path, match._)
  --     assert.spy(handler).called_with("add", teste1Path, match._)
  --     assert.spy(handler).called_with("add", testf1Path, match._)
  --     assert.spy(handler).called_with("add", testg1Path, match._)
  --     assert.spy(handler).called_with("add", testh1Path, match._)
  --     assert.spy(handler).called_with("add", testi1Path, match._)
  --   end)
  --
  --   it("should emit `addDir` event when directory was added", function()
  --     local handler = spy.new()
  --     watcher = FS.watch(temp_dir, handler)
  --
  --     wait_watcher_to_be_ready(watcher)
  --
  --     local test_dir = Path.join(temp_dir, "subdir")
  --
  --     FS.mkdir(test_dir)
  --
  --     assert.is_true(wait_event(watcher, "add_dir"), "Expected 'add_dir' event for created directory")
  --     assert.spy(handler).called(1)
  --     assert.spy(handler).called_with("add_dir", test_dir, match._)
  --   end)
  --
  --   it("should emit `change` event when file was changed", function()
  --     local test_path = get_fixture_path(temp_dir, "change.txt")
  --
  --     FS.writefile(test_path, "test")
  --
  --     local handler = spy.new()
  --     watcher = FS.watch(temp_dir, handler)
  --
  --     wait_watcher_to_be_ready(watcher)
  --
  --     assert.spy(handler).called(0)
  --
  --     write_file(test_path, tostring(vim.uv.now()))
  --
  --     assert.is_true(wait_event(watcher, "change"), "Expected 'change' event for created file")
  --     assert.spy(handler).called(1)
  --     assert.spy(handler).called_with("change", test_path, match._)
  --   end)
  --
  --   it("should emit `unlink` event when file was removed", function()
  --     local test_path = get_fixture_path(temp_dir, "unlink.txt")
  --
  --     FS.writefile(test_path, "test")
  --
  --     local handler = spy.new()
  --     watcher = FS.watch(temp_dir, handler)
  --
  --     wait_watcher_to_be_ready(watcher)
  --
  --     assert.spy(handler).called(0)
  --
  --     FS.rm(test_path)
  --
  --     assert.is_true(wait_event(watcher, "unlink"), "Expected 'unlink' event for created file")
  --     assert.spy(handler).called(1)
  --     assert.spy(handler).called_with("unlink", test_path, match._)
  --   end)
  --
  --   it("should emit `unlinkDir` event when a directory was removed", function()
  --     local test_dir = Path.join(temp_dir, "subdir")
  --
  --     FS.mkdir(test_dir)
  --
  --     local handler = spy.new()
  --     watcher = FS.watch(temp_dir, handler)
  --
  --     wait_watcher_to_be_ready(watcher)
  --
  --     assert.spy(handler).called(0)
  --
  --     FS.rm(test_dir)
  --
  --     assert.is_true(wait_event(watcher, "unlink_dir"), "Expected 'unlink_dir' event for created folder")
  --     assert.spy(handler).called(1)
  --     assert.spy(handler).called_with("unlink_dir", test_dir, match._)
  --   end)
  --
  --   it("should emit two `unlinkDir` event when two nested directories were removed", function()
  --     local test_dir = get_fixture_path(temp_dir, "subdir")
  --     local test_dir2 = get_fixture_path(temp_dir, "subdir/subdir2")
  --     local test_dir3 = get_fixture_path(temp_dir, "subdir/subdir2/subdir3")
  --
  --     FS.mkdir(test_dir)
  --     FS.mkdir(test_dir2)
  --     FS.mkdir(test_dir3)
  --
  --     local handler = spy.new()
  --     watcher = FS.watch(temp_dir, { recursive = true }, handler)
  --
  --     wait_watcher_to_be_ready(watcher)
  --
  --     FS.rm(test_dir2, { recursive = true })
  --
  --     assert.is_true(wait_event(watcher, "unlink_dir", 2), "Expected 'unlink_dir' event for created folder")
  --     assert.spy(handler).called(2)
  --     assert.spy(handler).called_with("unlink_dir", test_dir2, match._)
  --     assert.spy(handler).called_with("unlink_dir", test_dir3, match._)
  --   end)
  --
  --   it("should emit `unlink` and `add` events when a file is renamed", function()
  --     local test_path = get_fixture_path(temp_dir, "change.txt")
  --     local new_path = get_fixture_path(temp_dir, "moved.txt")
  --
  --     FS.writefile(test_path, "test")
  --
  --     local handler = spy.new()
  --     watcher = FS.watch(temp_dir, handler)
  --
  --     wait_watcher_to_be_ready(watcher)
  --
  --     FS.rename(test_path, new_path)
  --
  --     wait_event(watcher, "add")
  --
  --     assert.spy(handler).called(2)
  --     assert.spy(handler).called_with("unlink", test_path, match._)
  --     assert.spy(handler).called_with("add", new_path, match._)
  --   end)
  --
  --   it("should emit `add`, not `change`, when previously deleted file is re-added", function()
  --     local test_path = get_fixture_path(temp_dir, "add.txt")
  --
  --     local handler = spy.new()
  --     watcher = FS.watch(temp_dir, handler)
  --     wait_watcher_to_be_ready(watcher)
  --
  --     FS.writefile(test_path, "test")
  --
  --     assert.is_true(wait_event(watcher, "add"), "Expected 'add' event for created file")
  --     assert.spy(handler).called(1)
  --     assert.spy(handler).called_with("add", test_path, match._)
  --
  --     FS.rm(test_path)
  --
  --     assert.is_true(wait_event(watcher, "unlink"), "Expected 'unlink' event for created file")
  --     assert.spy(handler).called(2)
  --     assert.spy(handler).called_with("unlink", test_path, match._)
  --
  --     FS.writefile(test_path, tostring(vim.uv.now()))
  --
  --     assert.is_true(wait_event(watcher, "add"), "Expected 'add' event for created file")
  --     assert.spy(handler).called(3)
  --     assert.spy(handler).called_with("add", test_path, match._)
  --     assert.spy(handler).was_not_called_with("change", test_path, match._)
  --   end)
  --
  --   it("should not emit `unlink` for previously moved files", function()
  --     local test_path = get_fixture_path(temp_dir, "change.txt")
  --     local new_path1 = get_fixture_path(temp_dir, "moved.txt")
  --     local new_path2 = get_fixture_path(temp_dir, "moved-again.txt")
  --
  --     FS.writefile(test_path, "test")
  --
  --     local handler = spy.new()
  --     watcher = FS.watch(temp_dir, handler)
  --     wait_watcher_to_be_ready(watcher)
  --
  --     FS.rename(test_path, new_path1)
  --
  --     vim.wait(450) -- changed for a flaky test situation
  --
  --     FS.rename(new_path1, new_path2)
  --
  --     assert.is_true(wait_event(watcher, "unlink"), "Expected 'unlink' event for created file")
  --
  --     assert.spy(handler).called(4)
  --     assert.spy(handler).called_with("unlink", test_path, match._)
  --     assert.spy(handler).called_with("add", new_path1, match._)
  --     assert.spy(handler).called_with("unlink", new_path1, match._)
  --     assert.spy(handler).called_with("add", new_path2, match._)
  --     assert.spy(handler).was_not_called_with("unlink", new_path2._, match._)
  --     assert.spy(handler).was_not_called_with("add", test_path, match._)
  --     assert.spy(handler).was_not_called_with("change", match._, match._)
  --   end)
  --
  --   it("should notice when a file appears in a new directory", function()
  --     local test_dir = get_fixture_path(temp_dir, "subdir")
  --     local test_path = get_fixture_path(test_dir, "add.txt") -- NOTE: change
  --
  --     local handler = spy.new()
  --     watcher = FS.watch(temp_dir, { recursive = true }, handler)
  --     wait_watcher_to_be_ready(watcher)
  --
  --     FS.mkdir(test_dir)
  --
  --     assert.is_true(wait_event(watcher, "add_dir"), "Expected 'add_dir' event for created file")
  --     vim.wait(200)
  --
  --     FS.writefile(test_path, "test")
  --
  --     assert.is_true(wait_event(watcher, "add"), "Expected 'add' event for created file")
  --     assert.spy(handler).called(2)
  --     assert.spy(handler).called_with("add_dir", test_dir, match._)
  --     assert.spy(handler).called_with("add", test_path, match._)
  --   end)
  --
  --   it("should watch removed and re-added directories", function()
  --     local parent_path = get_fixture_path(temp_dir, "subdir2")
  --     local sub_path = get_fixture_path(temp_dir, "subdir2/subsub") -- NOTE: change
  --     local sub_file = get_fixture_path(sub_path, "somefile") -- NOTE: change
  --
  --     local handler = spy.new()
  --     watcher = FS.watch(temp_dir, { recursive = true }, handler)
  --     wait_watcher_to_be_ready(watcher)
  --
  --     FS.mkdir(parent_path)
  --     vim.wait(300)
  --
  --     FS.rm(parent_path)
  --
  --     assert.is_true(wait_event(watcher, "unlink_dir"), "Expected 'unlink_dir' event for created file")
  --     assert.spy(handler).called(2)
  --     assert.spy(handler).called_with("add_dir", parent_path, match._)
  --     assert.spy(handler).called_with("unlink_dir", parent_path, match._)
  --
  --     FS.mkdir(parent_path)
  --     vim.wait(2200)
  --
  --     FS.mkdir(sub_path)
  --
  --     assert.is_true(wait_event(watcher, "add_dir"), "Expected 'add_dir' event for created file")
  --     assert.spy(handler).called(4)
  --     assert.spy(handler).called_with("add_dir", sub_path, match._)
  --
  --     vim.wait(300)
  --     FS.writefile(sub_file, "test")
  --
  --     assert.is_true(wait_event(watcher, "add"), "Expected 'add' event for created file")
  --     assert.spy(handler).called(5)
  --     assert.spy(handler).called_with("add", sub_file, match._)
  --     assert.spy(handler).was_not_called_with("add", parent_path, match._)
  --     assert.spy(handler).was_not_called_with("add", sub_path, match._)
  --   end)
  --
  --   it("should emit `unlinkDir` and `add` when dir is replaced by file", function()
  --     local test_path = get_fixture_path(temp_dir, "dir_file")
  --
  --     FS.mkdir(test_path)
  --     vim.wait(300)
  --
  --     local handler = spy.new()
  --     watcher = FS.watch(temp_dir, handler)
  --     wait_watcher_to_be_ready(watcher)
  --
  --     FS.rm(test_path)
  --
  --     assert.is_true(wait_event(watcher, "unlink_dir"), "Expected 'unlink_dir' event for created directory")
  --     assert.spy(handler).called(1)
  --     assert.spy(handler).called_with("unlink_dir", test_path, match._)
  --
  --     FS.writefile(test_path, "file content")
  --
  --     assert.is_true(wait_event(watcher, "add"), "Expected 'add' event for created file")
  --     assert.spy(handler).called(2)
  --     assert.spy(handler).called_with("unlink_dir", test_path, match._)
  --     assert.spy(handler).called_with("add", test_path, match._)
  --     assert.spy(handler).was_not_called_with("add_dir", sub_path, match._)
  --   end)
  --
  --   it("should emit `unlink` and `addDir` when file is replaced by dir", function()
  --     local test_path = get_fixture_path(temp_dir, "dir_file")
  --
  --     FS.writefile(test_path, "file content")
  --
  --     local handler = spy.new()
  --     watcher = FS.watch(temp_dir, handler)
  --     wait_watcher_to_be_ready(watcher)
  --
  --     FS.rm(test_path)
  --
  --     vim.wait(300)
  --
  --     FS.mkdir(test_path)
  --
  --     assert.is_true(wait_event(watcher, "add_dir"), "Expected 'add' event for created file")
  --     assert.spy(handler).called(2)
  --     assert.spy(handler).called_with("unlink", test_path, match._)
  --     assert.spy(handler).called_with("add_dir", test_path, match._)
  --   end)
  --
  --   it("renaming a folder works correctly", function()
  --     local test_path = get_fixture_path(temp_dir, "dir_file")
  --     local new_path = get_fixture_path(temp_dir, "new_dir")
  --
  --     FS.mkdir(test_path)
  --
  --     local handler = spy.new()
  --     watcher = FS.watch(temp_dir, handler)
  --     wait_watcher_to_be_ready(watcher)
  --
  --     FS.rename(test_path, new_path)
  --
  --     assert.is_true(wait_event(watcher, "add_dir"), "Expected 'add' event for created dir")
  --     assert.spy(handler).called(2)
  --     assert.spy(handler).called_with("unlink_dir", test_path, match._)
  --     assert.spy(handler).called_with("add_dir", new_path, match._)
  --   end)
  -- end)
  --
  -- describe("watch individual files", function()
  --   it("should detect changes", function()
  --     local test_path = get_fixture_path(temp_dir, "change.txt")
  --
  --     FS.writefile(test_path, "something")
  --
  --     local handler = spy.new()
  --     watcher = FS.watch(test_path, handler)
  --     wait_watcher_to_be_ready(watcher)
  --
  --     FS.appendfile(test_path, " adding smt")
  --
  --     assert.is_true(wait_event(watcher, "change"), "Expected 'change' event for created file")
  --     assert.spy(handler).called(1)
  --     assert.spy(handler).called_with("change", test_path, match._)
  --   end)
  --
  --   it("should detect unlinks", function()
  --     local test_path = get_fixture_path(temp_dir, "unlink.txt")
  --
  --     FS.writefile(test_path, "test")
  --
  --     local handler = spy.new()
  --     watcher = FS.watch(test_path, handler)
  --     wait_watcher_to_be_ready(watcher)
  --
  --     FS.rm(test_path)
  --
  --     assert.is_true(wait_event(watcher, "unlink"), "Expected 'unlink' event for created file")
  --     assert.spy(handler).called(1)
  --     assert.spy(handler).called_with("unlink", test_path, match._)
  --   end)
  --
  --   it("should detect unlink and detect re-add", function()
  --     local test_path = get_fixture_path(temp_dir, "unlink.txt")
  --
  --     FS.writefile(test_path, "test")
  --
  --     local handler = spy.new()
  --     watcher = FS.watch(test_path, handler)
  --     wait_watcher_to_be_ready(watcher)
  --
  --     FS.rm(test_path)
  --
  --     assert.is_true(wait_event(watcher, "unlink"), "Expected 'unlink' event for created file")
  --     assert.spy(handler).called(1)
  --     assert.spy(handler).called_with("unlink", test_path, match._)
  --
  --     vim.wait(200)
  --     FS.writefile(test_path, "something")
  --
  --     assert.is_true(wait_event(watcher, "add"), "Expected 'add' event for created file")
  --     assert.spy(handler).called(2)
  --     assert.spy(handler).called_with("add", test_path, match._)
  --   end)
  --
  --   it("should ignore unwatched siblings", function()
  --     local test_path = get_fixture_path(temp_dir, "add.txt")
  --     local sibling_path = get_fixture_path(temp_dir, "change.txt")
  --
  --     local handler = spy.new()
  --     watcher = FS.watch(test_path, handler)
  --
  --     vim.wait(300)
  --
  --     FS.writefile(test_path, "asdasd")
  --     FS.writefile(sibling_path, " nanana")
  --
  --     vim.wait(200)
  --
  --     assert.spy(handler).called(1)
  --     assert.spy(handler).called_with("add", test_path, match._)
  --   end)
  --
  --   it("should detect safe-edit", function()
  --     local test_path = get_fixture_path(temp_dir, "change.txt")
  --     local safe_path = get_fixture_path(temp_dir, "tmp.txt")
  --
  --     FS.writefile(test_path, "test")
  --
  --     local handler = spy.new()
  --     watcher = FS.watch(test_path, handler)
  --     wait_watcher_to_be_ready(watcher)
  --
  --     wait(200)
  --     FS.appendfile(safe_path, " first")
  --     FS.rename(safe_path, test_path)
  --
  --     wait(300)
  --
  --     FS.writefile(safe_path, "last_add")
  --     FS.rename(safe_path, test_path)
  --
  --     wait(300)
  --
  --     FS.writefile(safe_path, "next_add")
  --     FS.rename(safe_path, test_path)
  --
  --     wait(300)
  --
  --     FS.appendfile(safe_path, "nana")
  --
  --     wait(300)
  --
  --     assert.spy(handler).called(3)
  --     assert.spy(handler).called_with("change", test_path, match._)
  --     assert.spy(handler).was_not_called_with("add", sub_path, match._)
  --     assert.spy(handler).was_not_called_with("unlink", sub_path, match._)
  --     assert.spy(handler).was_not_called_with("add_dir", sub_path, match._)
  --     assert.spy(handler).was_not_called_with("unlink_dir", sub_path, match._)
  --   end)
  --
  --   describe("gh-682 should detect unlink then re-adds", function()
  --     -- NOTE: Fix nil lookup and revert this test case to previous version
  --     it("should detect unlink while watching a non-existent second file in another directory", function()
  --       local test_path = get_fixture_path(temp_dir, "unlink.txt")
  --       local other_dir_path = get_fixture_path(temp_dir, "other-dir")
  --
  --       FS.writefile(test_path, "test")
  --       FS.mkdir(other_dir_path)
  --
  --       local handler = spy.new()
  --       watcher = FS.watch({ test_path, other_dir_path }, handler)
  --
  --       wait(300)
  --       -- intentionally for this test don't write fs.writeFileSync(otherPath, 'other');
  --
  --       FS.rm(test_path)
  --
  --       assert.is_true(wait_event(watcher, "unlink"), "Expected 'unlink' event for created file")
  --       assert.spy(handler).called(1)
  --       assert.spy(handler).called_with("unlink", test_path, nil)
  --     end)
  --
  --     it("should detect unlink and re-add while watching a second file", function()
  --       -- options.ignoreInitial = true;
  --       local test_path = get_fixture_path(temp_dir, "unlink.txt")
  --       local other_path = get_fixture_path(temp_dir, "other.txt")
  --
  --       FS.writefile(other_path, "something")
  --       FS.writefile(test_path, "something")
  --
  --       -- _G.DEBUG = true
  --
  --       local handler = spy.new()
  --       watcher = FS.watch(test_path, handler)
  --
  --       wait(300)
  --
  --       FS.rm(test_path)
  --
  --       assert.is_true(wait_event(watcher, "unlink"), "Expected 'unlink' event for created file")
  --       assert.spy(handler).called(1)
  --       assert.spy(handler).called_with("unlink", test_path, nil)
  --
  --       wait(300)
  --
  --       FS.writefile(test_path, "re-added")
  --
  --       wait(300)
  --
  --       -- NOTE: this doesnt work, watcher changes or doesnt get the add
  --       -- assert.is_true(wait_event(watcher, "add", 3000), "Expected 'add' event for created file")
  --       assert.spy(handler).called(2)
  --       assert.spy(handler).called_with("add", test_path, match._)
  --     end)
  --
  --     --  TODO: causes a problem in entire test suite
  --     it("should detect unlink and re-add while watching a non-existent second file in another directory", function()
  --       local test_path = get_fixture_path(temp_dir, "unlink.txt")
  --       local other_dir_path = get_fixture_path(temp_dir, "other-dir")
  --       local other_path = get_fixture_path(other_dir_path, "other.txt")
  --
  --       FS.writefile(test_path, "something")
  --       FS.mkdir(other_dir_path)
  --
  --       local handler = spy.new()
  --       watcher = FS.watch({ test_path, other_path }, handler)
  --
  --       wait(300)
  --
  --       FS.rm(test_path)
  --
  --       assert.is_true(wait_event(watcher, "unlink"), "Expected 'unlink' event for created file")
  --       assert.spy(handler).called(1)
  --
  --       wait(300) -- This fixes the test case
  --
  --       FS.writefile(test_path, "re-added")
  --
  --       assert.is_true(wait_event(watcher, "add"), "Expected 'add' event for created file")
  --       assert.spy(handler).called(2)
  --       assert.spy(handler).called_with("add", test_path, match._)
  --     end)
  --
  --     it("should detect unlink and re-add while watching a non-existent second file in the same directory", function()
  --       local test_path = get_fixture_path(temp_dir, "unlink.txt")
  --       local other_path = get_fixture_path(temp_dir, "other.txt")
  --
  --       FS.writefile(test_path, "something")
  --       -- FS.writefile(other_path, "other something")
  --
  --       local handler = spy.new()
  --       watcher = FS.watch({ test_path, other_path }, handler)
  --
  --       wait(300)
  --
  --       FS.rm(test_path)
  --
  --       assert.is_true(wait_event(watcher, "unlink"), "Expected 'unlink' event for created file")
  --       assert.spy(handler).called(1)
  --       assert.spy(handler).called_with("unlink", test_path, nil)
  --
  --       wait(300)
  --
  --       FS.writefile(test_path, "re-added")
  --
  --       assert.is_true(wait_event(watcher, "add"), "Expected 'add' event for created file")
  --       assert.spy(handler).called(2)
  --       assert.spy(handler).called_with("add", test_path, match._)
  --     end)
  --
  --     -- NOTE: Adjustments start from here
  --     it("should detect two unlinks and one re-add", function()
  --       local test_path = get_fixture_path(temp_dir, "unlink.txt")
  --       local other_path = get_fixture_path(temp_dir, "other.txt")
  --
  --       FS.writefile(test_path, "something")
  --       FS.writefile(other_path, "other something")
  --
  --       local handler = spy.new()
  --       watcher = FS.watch({ test_path, other_path }, handler)
  --
  --       wait(300)
  --
  --       FS.rm(other_path)
  --
  --       assert.is_true(wait_event(watcher, "unlink"), "Expected 'unlink' event for created file")
  --       assert.spy(handler).called(1)
  --       assert.spy(handler).called_with("unlink", other_path, nil)
  --
  --       FS.rm(test_path)
  --
  --       assert.is_true(wait_event(watcher, "unlink"), "Expected 'unlink' event for created file")
  --       assert.spy(handler).called(2)
  --       assert.spy(handler).called_with("unlink", test_path, nil)
  --
  --       wait(300)
  --
  --       FS.writefile(test_path, "re-added")
  --
  --       assert.is_true(wait_event(watcher, "add"), "Expected 'add' event for created file")
  --       assert.spy(handler).called(3)
  --       assert.spy(handler).called_with("add", test_path, match._)
  --     end)
  --
  --     it("should detect unlink and re-add while watching a second file and a non-existent third file", function()
  --       local test_path = get_fixture_path(temp_dir, "unlink.txt")
  --       local other_path = get_fixture_path(temp_dir, "other.txt")
  --       local other_path2 = get_fixture_path(temp_dir, "other2.txt")
  --
  --       FS.writefile(test_path, "something")
  --       FS.writefile(other_path, "other something")
  --
  --       local handler = spy.new()
  --       watcher = FS.watch({ test_path, other_path, other_path2 }, handler)
  --
  --       wait(300)
  --
  --       FS.rm(test_path)
  --
  --       assert.is_true(wait_event(watcher, "unlink"), "Expected 'unlink' event for created file")
  --       assert.spy(handler).called(1)
  --       assert.spy(handler).called_with("unlink", test_path, nil)
  --
  --       wait(300)
  --
  --       FS.writefile(test_path, "re-added")
  --
  --       assert.is_true(wait_event(watcher, "add"), "Expected 'add' event for created file")
  --       assert.spy(handler).called(2)
  --       assert.spy(handler).called_with("add", test_path, match._)
  --     end)
  --   end)
  -- end)
  --
  -- describe("renamed directory", function()
  --   it("should emit `add` for a file in a renamed directory", function()
  --     local test_dir = get_fixture_path(temp_dir, "subdir")
  --     local test_path = get_fixture_path(test_dir, "add.txt")
  --     local renamed_dir = get_fixture_path(temp_dir, "subdir-renamed")
  --
  --     local expected_path = get_fixture_path(renamed_dir, "add.txt")
  --
  --     FS.mkdir(test_dir)
  --
  --     FS.writefile(test_path, "something")
  --
  --     local handler = spy.new()
  --     watcher = FS.watch(temp_dir, handler)
  --
  --     wait(1000) -- instead wait ready, reduce it!
  --
  --     FS.rename(test_dir, renamed_dir)
  --
  --     assert.is_true(wait_event(watcher, "unlink_dir"), "Expected 'unlink' event for created folder")
  --     assert.spy(handler).called(2)
  --     assert.spy(handler).called_with("unlink_dir", test_dir, nil)
  --     assert.spy(handler).called_with("add_dir", renamed_dir, match._)
  --     -- TODO: Chokidar fires these events, I fire less:
  --     -- assert.spy(handler).called_with("unlink", test_path, match._)
  --     -- assert.spy(handler).called_with("add", expected_path, nil)
  --   end)
  -- end)
  --
  -- describe("watch non-existent paths", function()
  --   it("should watch non-existent file and detect add", function()
  --     local test_path = get_fixture_path(temp_dir, "add.txt")
  --
  --     local handler = spy.new()
  --     watcher = FS.watch(test_path, handler)
  --
  --     wait(300)
  --
  --     FS.writefile(test_path, "something")
  --
  --     assert.is_true(wait_event(watcher, "add"), "Expected 'unlink' event for created folder")
  --     assert.spy(handler).called(1)
  --     assert.spy(handler).called_with("add", test_path, match._)
  --   end)
  --
  --   it("should watch non-existent dir and detect addDir/add", function()
  --     local test_dir = get_fixture_path(temp_dir, "subdir")
  --     local test_path = get_fixture_path(test_dir, "add.txt")
  --
  --     local handler = spy.new()
  --     watcher = FS.watch(test_dir, handler)
  --
  --     wait(300)
  --
  --     FS.mkdir(test_dir)
  --
  --     assert.is_true(wait_event(watcher, "add_dir"), "Expected 'add_dir' event for created folder")
  --     assert.spy(handler).called(1)
  --     assert.spy(handler).called_with("add_dir", test_dir, match._)
  --
  --     wait(300)
  --
  --     FS.writefile(test_path, "cool")
  --
  --     assert.is_true(wait_event(watcher, "add"), "Expected 'add' event for created file")
  --     assert.spy(handler).called(2)
  --     assert.spy(handler).called_with("add", test_path, match._)
  --   end)
  -- end)
  --
  -- describe("watch symlinks", function()
  --   local source_dir, sub_dir, linked_dir
  --
  --   before_each(function()
  --     source_dir = get_fixture_path(temp_dir, "link-source")
  --     linked_dir = Path.join(temp_dir, "link-folder")
  --     sub_dir = get_fixture_path(source_dir, "subdir")
  --
  --     FS.mkdir(source_dir)
  --
  --     FS.mkdir(sub_dir)
  --     FS.writefile(get_fixture_path(sub_dir, "add.txt"), "something")
  --   end)
  --
  --   after_each(function()
  --     FS.unlink(linked_dir)
  --     FS.unlink(source_dir)
  --   end)
  --   -- TODO: temp_dirs are symlink dirs from? current_dir, also sub_dir and add.txt always get created
  --   --
  --
  --   it("should watch symlinked dirs", function()
  --     local change_path = get_fixture_path(source_dir, "change.txt")
  --     local unlink_path = get_fixture_path(source_dir, "unlink.txt")
  --
  --     FS.writefile(change_path, "something")
  --     FS.writefile(unlink_path, "another thing")
  --
  --     local handler = spy.new()
  --     watcher = FS.watch(linked_dir, handler)
  --
  --     wait(300)
  --
  --     FS.symlink(source_dir, linked_dir)
  --
  --     wait(300)
  --
  --     assert.spy(handler).called(1)
  --     assert.spy(handler).called_with("add_dir", linked_dir, match._)
  --     -- NOTE: On chokidar, events traverse down the directories:
  --     -- assert.spy(handler).called_with("add", change_path, match._)
  --     -- assert.spy(handler).called_with("add", unlink_path, match._)
  --   end)
  --
  --   it("should watch symlinked files", function()
  --     local change_path = get_fixture_path(source_dir, "change.txt")
  --     local link_path = get_fixture_path(source_dir, "link.txt")
  --
  --     FS.writefile(change_path, "something")
  --     FS.symlink(change_path, link_path)
  --
  --     local handler = spy.new()
  --     watcher = FS.watch(link_path, handler)
  --
  --     wait(300)
  --
  --     FS.appendfile(change_path, "adding something")
  --
  --     assert.is_true(wait_event(watcher, "change"), "Expected 'change' event for created file")
  --     assert.spy(handler).called(1)
  --     assert.spy(handler).called_with("change", link_path, match._)
  --   end)
  --
  --   it("should follow symlinked files within a normal dir", function()
  --     local change_path = get_fixture_path(source_dir, "change.txt")
  --     local link_path = get_fixture_path(sub_dir, "link.txt")
  --
  --     FS.writefile(change_path, "something")
  --     FS.symlink(change_path, link_path)
  --
  --     local handler = spy.new()
  --     watcher = FS.watch(sub_dir, handler)
  --
  --     wait(300)
  --
  --     FS.appendfile(change_path, "adding something") -- NOTE: This doesn't fire symlinks
  --
  --     assert.is_true(wait_event(watcher, "change"), "Expected 'change' event for created file")
  --     assert.spy(handler).called(1)
  --     assert.spy(handler).called_with("change", link_path, match._)
  --   end)
  --
  --   it("should watch paths with a symlinked parent", function()
  --     local test_file = get_fixture_path(sub_dir, "add.txt")
  --
  --     FS.symlink(source_dir, linked_dir)
  --
  --     local handler = spy.new()
  --     watcher = FS.watch(sub_dir, handler)
  --
  --     wait(300)
  --
  --     FS.appendfile(test_file, "adding something") -- NOTE: This doesn't fire symlinks
  --
  --     assert.is_true(wait_event(watcher, "change"), "Expected 'change' event for created file")
  --     assert.spy(handler).called(1)
  --     assert.spy(handler).called_with("change", test_file, match._)
  --   end)
  --
  --   it("should not recurse indefinitely on circular symlinks", function()
  --     FS.symlink(source_dir, Path.join(sub_dir, "circular"))
  --
  --     local handler = spy.new()
  --     watcher = FS.watch(source_dir, handler)
  --
  --     wait(300)
  --
  --     assert.is_equal(watcher.status, "watching")
  --   end)
  --
  --   it("should recognize changes following symlinked dirs", function()
  --     local change_path = get_fixture_path(source_dir, "change.txt")
  --
  --     FS.writefile(change_path, "something")
  --     FS.symlink(source_dir, linked_dir)
  --
  --     local linked_file_path = Path.join(linked_dir, "change.txt")
  --
  --     local handler = spy.new()
  --     watcher = FS.watch(linked_dir, handler)
  --
  --     wait(300)
  --
  --     FS.appendfile(change_path, " one two")
  --
  --     assert.is_true(wait_event(watcher, "change"), "Expected 'change' event for created file")
  --     assert.spy(handler).called(1)
  --     assert.spy(handler).called_with("change", linked_file_path, match._)
  --   end)
  --
  --   it("should follow newly created symlinks", function()
  --     local link_dir = Path.join(source_dir, "link")
  --
  --     local handler = spy.new()
  --     watcher = FS.watch(source_dir, handler)
  --
  --     wait_watcher_to_be_ready(watcher)
  --
  --     FS.symlink(sub_dir, link_dir)
  --
  --     wait(300)
  --
  --     -- assert.is_true(wait_event(watcher, "add"), "Expected 'change' event for created file") -- NOTE: On chokidar, events traverse down the directories:
  --     assert.spy(handler).called(1)
  --     assert.spy(handler).called_with("add_dir", link_dir, match._)
  --     -- assert.spy(handler).called_with("add", Path.join(link_dir, "add.txt"), match._)
  --   end)
  --
  --   it("should not reuse watcher when following a symlink to elsewhere", function()
  --     local linked_path = Path.join(source_dir, "outside")
  --     local linked_file_path = Path.join(linked_path, "text.txt")
  --     local link_path = Path.join(source_dir, "subdir/subsub")
  --
  --     FS.mkdir(linked_path)
  --     FS.writefile(linked_file_path, "something")
  --     FS.symlink(linked_path, link_path)
  --
  --     local handler = spy.new()
  --     local watcher2 = FS.watch(sub_dir, handler)
  --
  --     wait_watcher_to_be_ready(watcher2)
  --
  --     local watched_path = Path.join(sub_dir, "subsub/text.txt")
  --     local other_handler = spy.new()
  --     watcher = FS.watch(watched_path, other_handler)
  --
  --     wait_watcher_to_be_ready(watcher)
  --
  --     FS.appendfile(watched_path, " another one")
  --
  --     wait(300)
  --
  --     assert.spy(other_handler).called(1)
  --     assert.spy(other_handler).called_with("change", watched_path, match._)
  --
  --     watcher2:stop() -- NOTE: unwatch gives a runtime error
  --   end)
  --
  --   it("should emit ready event even when broken symlinks are encountered", function()
  --     local target_dir = Path.join(sub_dir, "nonexistent")
  --
  --     FS.mkdir(target_dir)
  --
  --     FS.symlink(target_dir, Path.join(sub_dir, "broken"))
  --
  --     FS.rmdir(target_dir)
  --
  --     local handler = spy.new()
  --     watcher = FS.watch(sub_dir, handler)
  --
  --     wait_watcher_to_be_ready(watcher)
  --     assert.is_equal(watcher.status, "watching")
  --   end)
  -- end)

  describe("cwd", function()
    it("should emit relative paths based on cwd", function()
      local has_change_txt = FS.stat("./change.txt")
      if has_change_txt then
        FS.unlink("./change.txt")
      end
      local has_unlink_txt = vim.uv.fs_stat("./unlink.txt")
      if has_unlink_txt then
        FS.unlink("./unlink.txt")
      end

      local cwd = vim.uv.cwd()
      local handler = spy.new()
      watcher = FS.watch(".", handler)

      wait_watcher_to_be_ready(watcher)

      FS.writefile("./change.txt", "something")
      FS.writefile("./unlink.txt", "unlink something")

      wait(150)

      assert.spy(handler).called_with("add", cwd .. "/change.txt", match.is_table())
      assert.spy(handler).called_with("add", cwd .. "/unlink.txt", match.is_table())

      FS.appendfile("./change.txt", " adding something more")

      wait(150)

      assert.spy(handler).called_with("change", cwd .. "/change.txt", match.is_table())

      FS.unlink("./unlink.txt")

      assert.is_true(wait_event(watcher, "unlink"), "Expected 'change' event for created file")
      assert.spy(handler).called(4)
      assert.spy(handler).called_with("unlink", cwd .. "/unlink.txt", nil)

      watcher:stop() -- TODO: Make it stop the watching by clearing out the relevant stat tree(?)
    end)

    -- NOTE: This fails because of multiple watcher problem
    -- it("should emit `addDir` with alwaysStat for renamed directory", function()
    --   local cwd_test_dir = vim.uv.cwd() .. os.tmpname()
    --
    --   os.remove(cwd_test_dir)
    --   assert(FS.mkdir(cwd_test_dir), "Failed to create temp directory")
    --
    --   local test_dir = get_fixture_path(cwd_test_dir, "subdir")
    --   local renamed_dir = get_fixture_path(cwd_test_dir, "subdir-renamed")
    --
    --   p("IZZZZZZZZZZZO")
    --   p(test_dir)
    --
    --   FS.mkdir(test_dir)
    --
    --   local cwd = vim.uv.cwd()
    --   local handler = spy.new()
    --
    --   watcher = FS.watch(".", { recursive = true }, handler)
    --
    --   wait_watcher_to_be_ready(watcher)
    --
    --   FS.rename(test_dir, renamed_dir)
    --
    --   assert.is_true(wait_event(watcher, "add_dir"), "Expected 'add' event for created dir")
    --   assert.spy(handler).called(2)
    --   assert.spy(handler).called_with("unlink_dir", test_dir, match._)
    --   assert.spy(handler).called_with("add_dir", renamed_dir, match._)
    -- end)

    -- TODO: This is important next addition
    -- it("should allow separate watchers to have different cwds", function() -- make this 2nd one a path with ../
    --   -- TODO: Not finished, make multiple watchers possible to be registered, necessary for addons that are unrelated
    --   local cwd_test_dir = vim.uv.cwd() .. os.tmpname()
    --
    --   os.remove(cwd_test_dir)
    --   assert(FS.mkdir(cwd_test_dir), "Failed to create temp directory")
    --
    --   local test_dir = get_fixture_path(cwd_test_dir, "cwd-multi-dir")
    --   local test_sub_dir = get_fixture_path(cwd_test_dir, "cwd-multi-dir/subdir")
    --
    --   FS.mkdir(test_dir)
    --   FS.mkdir(test_sub_dir)
    --
    --   local change_txt = "./cwd-multi-dir/subdir/change.txt"
    --   local unlink_txt = "./cwd-multi-dir/subdir/unlink.txt"
    --   local handler = spy.new()
    --   local secondHandler = spy.new()
    --   local thirdHandler = spy.new()
    --
    --   watcher = FS.watch(".", { recursive = true }, handler)
    --   local watcherTwo = FS.watch("./cwd-multi-dir", { recursive = true }, secondHandler)
    --
    --   wait_watcher_to_be_ready(watcher)
    --   wait_watcher_to_be_ready(watcherTwo)
    --
    --   wait(250)
    --
    --   FS.writefile(change_txt, "something")
    --   FS.writefile(unlink_txt, "unlink something")
    --
    --   wait(150)
    --
    --   FS.appendfile(change_txt, " something more")
    --
    --   -- local watcherThree = FS.watch("./cwd-multi-dir/subdir", thirdHandler)
    --
    --   wait(150)
    --
    --   FS.rm(unlink_txt)
    --
    --   assert.is_true(wait_event(watcher, "unlink"), "Expected 'add' event for created dir")
    --   assert.spy(handler).called(4)
    --   assert.spy(handler).called_with("add", change_txt, match._)
    --   assert.spy(handler).called_with("add", unlink_txt, match._)
    -- end)
  end)

  describe("get_watched_paths", function()
    it("should return the watched paths", function()
      local test_dir = get_fixture_path(temp_dir, "subdir")
      local add_txt = get_fixture_path(test_dir, "add.txt")
      local change_txt = get_fixture_path(test_dir, "change.txt")
      local another_txt = get_fixture_path(temp_dir, "another.txt")

      FS.writefile(another_txt, "something")
      FS.mkdir(test_dir)
      FS.writefile(add_txt, "something")
      FS.writefile(change_txt, "something")

      local handler = spy.new()
      watcher = FS.watch(temp_dir, { recursive = true }, handler)

      wait_watcher_to_be_ready(watcher)

      assert.are.same(List.sort(watcher:get_watched_paths()), {
        another_txt,
        test_dir,
        add_txt,
        change_txt,
      })
    end)
  end)

  describe("unwatch", function()
    -- beforeEach(async () => {
    --   options.ignoreInitial = true;
    --   await fs_mkdir(getFixturePath('subdir'), PERM_ARR);
    --   await delay();
    -- });

    -- NOTE: in the examples unwatch(and change) one folder and one file
    -- it("should stop watching when watcher is absolute", function()
    --   one.txt
    --   dir
    --     two.txt
    --     subdir
    --     three.txt
    --     four.txt
    --
    --   assert.spy(handler).called(0)
    --   assert.spy(handler).was.not.called_with("add", change_txt, match._)
    --
    --   -- local watch_paths = { }
    --
    --   -- const watchPaths = [getFixturePath('subdir'), getFixturePath('change.txt')];
    --   -- const watcher = chokidar_watch(watchPaths, options);
    --   -- const spy = await aspy(watcher, EV.ALL);
    --   -- watcher.unwatch(getFixturePath('subdir'));
    --   --
    --   -- await delay();
    --   -- await write(getFixturePath('subdir/add.txt'), dateNow());
    --   -- await write(getFixturePath('change.txt'), dateNow());
    --   -- await waitFor([spy]);
    --
    --   -- await delay(300);
    --   -- spy.should.have.been.calledWith(EV.CHANGE, getFixturePath('change.txt'));
    --   -- spy.should.not.have.been.calledWith(EV.ADD);
    --   -- if (!macosFswatch) spy.should.have.been.calledOnce;
    -- end)

    --   it('should unwatch when watcher is relative', async () => { -- on
    --     const fixturesDir = sysPath.relative(process.cwd(), currentDir);
    --     const subdir = sysPath.join(fixturesDir, 'subdir');
    --     const changeFile = sysPath.join(fixturesDir, 'change.txt');
    --     const watchPaths = [subdir, changeFile];
    --     const watcher = chokidar_watch(watchPaths, options);
    --     const spy = await aspy(watcher, EV.ALL);
    --
    --     await delay();
    --     watcher.unwatch(subdir);
    --     await write(getFixturePath('subdir/add.txt'), dateNow());
    --     await write(getFixturePath('change.txt'), dateNow());
    --     await waitFor([spy]);
    --
    --     await delay(300);
    --     spy.should.have.been.calledWith(EV.CHANGE, changeFile);
    --     spy.should.not.have.been.calledWith(EV.ADD);
    --     if (!macosFswatch) spy.should.have.been.calledOnce;
    --   });
    --
    --   it('should watch paths that were unwatched and added again', async () => {
    --     const spy = sinon.spy();
    --     const watchPaths = [getFixturePath('change.txt')];
    --     const watcher = chokidar_watch(watchPaths, options);
    --     await waitForWatcher(watcher);
    --
    --     await delay();
    --     watcher.unwatch(getFixturePath('change.txt'));
    --
    --     await delay();
    --     watcher.on(EV.ALL, spy).add(getFixturePath('change.txt'));
    --
    --     await delay();
    --     await write(getFixturePath('change.txt'), dateNow());
    --     await waitFor([spy]);
    --     spy.should.have.been.calledWith(EV.CHANGE, getFixturePath('change.txt'));
    --     if (!macosFswatch) spy.should.have.been.calledOnce;
    --   });
  end)
end)

-- TODO: IN FUTURE: maybe polling(?)
-- -- READ TEST SUITE: bug reproduction parts, close(!!), unwatch(!!)
