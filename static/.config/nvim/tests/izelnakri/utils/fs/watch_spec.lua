-- NOTE: Maybe in future implement atomic(swap file ignore) / ignore / ignoreInitials(tilde files, .dotfiles)
-- Changing a folder and changing a file triggers CHANGE
-- NOTE: on add dir, should I run through the folders and make all files and folders "add" and "add_dir"?
require("async.test")

local Path = require("izelnakri.utils.path")
local List = require("izelnakri.utils.list")
local wait = require("tests.utils.wait")

local uv = vim.uv
local FS = require("izelnakri.utils.fs")
local DEFAULT_TIMEOUT = 8000

-- Helper functions for tests
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

local function write_file(path, content)
  content = content or tostring(vim.uv.now())
  FS.writefile(path, content, function(err, result)
    if err then
      vim.print("ERRROR:")
      return vim.print(err)
    elseif _G.DEBUG then
      vim.print("FS.writefile successful for: " .. path)
    end
  end)
end

local function get_fixture_path(temp_dir, target_path)
  -- const subd = subdirId && subdirId.toString() || ''; -- NOTE: maybe add that subdirId
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

  describe("watch a directory", function()
    it("should expose public API methods", function()
      watcher = FS.watch(temp_dir, { recursive = false })
      assert.is_function(watcher.add_callback, "Expected 'add_callback' function")
      assert.is_function(watcher.stop, "Expected 'stop' function")
      assert.is_function(watcher.restart, "Expected 'restart' function")
    end)

    it("should emit `add` event when a file is created", function()
      local handler = spy.new()
      watcher = FS.watch(temp_dir, { recursive = true }, handler)

      wait_watcher_to_be_ready(watcher)

      local test_path = Path.join(temp_dir, "add.txt")
      FS.writefile(test_path, "test")

      assert.is_true(wait_event(watcher, "add"), "Expected 'add' event for created file")
      assert.spy(handler).called(1) -- NOTE: This has to be once only
      assert.are.equal(handler.calls[1].vals[1], "add")
      assert.are.equal(handler.calls[1].vals[2], temp_dir .. "/add.txt")
    end)

    it("should emit nine `add` events when nine files were added in one directory", function()
      local handler = spy.new()
      watcher = FS.watch(temp_dir, { recursive = false }, handler)
      wait_watcher_to_be_ready(watcher) -- NOTE: ESSENTIAL

      local paths = {}
      for i = 1, 9 do
        table.insert(paths, Path.join(temp_dir, "add" .. i .. ".txt"))
      end

      write_file(paths[1])
      write_file(paths[2])
      write_file(paths[3])
      write_file(paths[4])
      write_file(paths[5])

      vim.wait(100)

      write_file(paths[6])
      write_file(paths[7])

      vim.wait(150)

      write_file(paths[8])
      write_file(paths[9])

      wait_for_call_count(handler, 4)
      vim.wait(1000)
      wait_for_call_count(handler, 9)

      assert.spy(handler).called(9)
      for i = 1, #paths do
        assert.spy(handler).called_with("add", paths[i], match._)
      end
    end)

    it("should emit thirtythree `add` events when thirtythree files were added in nine directories", function()
      local test1Path = get_fixture_path(temp_dir, "add1.txt")
      local testb1Path = get_fixture_path(temp_dir, "b/add1.txt")
      local testc1Path = get_fixture_path(temp_dir, "c/add1.txt")
      local testd1Path = get_fixture_path(temp_dir, "d/add1.txt")
      local teste1Path = get_fixture_path(temp_dir, "e/add1.txt")
      local testf1Path = get_fixture_path(temp_dir, "f/add1.txt")
      local testg1Path = get_fixture_path(temp_dir, "g/add1.txt")
      local testh1Path = get_fixture_path(temp_dir, "h/add1.txt")
      local testi1Path = get_fixture_path(temp_dir, "i/add1.txt")
      local test2Path = get_fixture_path(temp_dir, "add2.txt")
      local testb2Path = get_fixture_path(temp_dir, "b/add2.txt")
      local testc2Path = get_fixture_path(temp_dir, "c/add2.txt")
      local test3Path = get_fixture_path(temp_dir, "add3.txt")
      local testb3Path = get_fixture_path(temp_dir, "b/add3.txt")
      local testc3Path = get_fixture_path(temp_dir, "c/add3.txt")
      local test4Path = get_fixture_path(temp_dir, "add4.txt")
      local testb4Path = get_fixture_path(temp_dir, "b/add4.txt")
      local testc4Path = get_fixture_path(temp_dir, "c/add4.txt")
      local test5Path = get_fixture_path(temp_dir, "add5.txt")
      local testb5Path = get_fixture_path(temp_dir, "b/add5.txt")
      local testc5Path = get_fixture_path(temp_dir, "c/add5.txt")
      local test6Path = get_fixture_path(temp_dir, "add6.txt")
      local testb6Path = get_fixture_path(temp_dir, "b/add6.txt")
      local testc6Path = get_fixture_path(temp_dir, "c/add6.txt")
      local test7Path = get_fixture_path(temp_dir, "add7.txt")
      local testb7Path = get_fixture_path(temp_dir, "b/add7.txt")
      local testc7Path = get_fixture_path(temp_dir, "c/add7.txt")
      local test8Path = get_fixture_path(temp_dir, "add8.txt")
      local testb8Path = get_fixture_path(temp_dir, "b/add8.txt")
      local testc8Path = get_fixture_path(temp_dir, "c/add8.txt")
      local test9Path = get_fixture_path(temp_dir, "add9.txt")
      local testb9Path = get_fixture_path(temp_dir, "b/add9.txt")
      local testc9Path = get_fixture_path(temp_dir, "c/add9.txt")

      FS.mkdir(get_fixture_path(temp_dir, "b"))
      FS.mkdir(get_fixture_path(temp_dir, "c"))
      FS.mkdir(get_fixture_path(temp_dir, "d"))
      FS.mkdir(get_fixture_path(temp_dir, "e"))
      FS.mkdir(get_fixture_path(temp_dir, "f"))
      FS.mkdir(get_fixture_path(temp_dir, "g"))
      FS.mkdir(get_fixture_path(temp_dir, "h"))
      FS.mkdir(get_fixture_path(temp_dir, "i"))

      vim.wait(500)

      local handler = spy.new()
      watcher = FS.watch(temp_dir, { recursive = true }, handler)
      wait_watcher_to_be_ready(watcher)

      local filesToWrite = {
        test1Path,
        test2Path,
        test3Path,
        test4Path,
        test5Path,
        test6Path,
        test7Path,
        test8Path,
        test9Path,
        testb1Path,
        testb2Path,
        testb3Path,
        testb4Path,
        testb5Path,
        testb6Path,
        testb7Path,
        testb8Path,
        testb9Path,
        testc1Path,
        testc2Path,
        testc3Path,
        testc4Path,
        testc5Path,
        testc6Path,
        testc7Path,
        testc8Path,
        testc9Path,
        testd1Path,
        teste1Path,
        testf1Path,
        testg1Path,
        testh1Path,
        testi1Path,
      }

      for _, fileToWrite in pairs(filesToWrite) do
        write_file(fileToWrite)
      end

      wait_for_call_count(handler, #filesToWrite)

      assert.spy(handler).called(33)
      assert.spy(handler).called_with("add", test1Path, match._)
      assert.spy(handler).called_with("add", test2Path, match._)
      assert.spy(handler).called_with("add", test3Path, match._)
      assert.spy(handler).called_with("add", test4Path, match._)
      assert.spy(handler).called_with("add", test5Path, match._)
      assert.spy(handler).called_with("add", test6Path, match._)
      assert.spy(handler).called_with("add", test7Path, match._)
      assert.spy(handler).called_with("add", test8Path, match._)
      assert.spy(handler).called_with("add", test9Path, match._)
      assert.spy(handler).called_with("add", testb1Path, match._)
      assert.spy(handler).called_with("add", testb2Path, match._)
      assert.spy(handler).called_with("add", testb3Path, match._)
      assert.spy(handler).called_with("add", testb4Path, match._)
      assert.spy(handler).called_with("add", testb5Path, match._)
      assert.spy(handler).called_with("add", testb6Path, match._)
      assert.spy(handler).called_with("add", testb7Path, match._)
      assert.spy(handler).called_with("add", testb8Path, match._)
      assert.spy(handler).called_with("add", testb9Path, match._)
      assert.spy(handler).called_with("add", testc1Path, match._)
      assert.spy(handler).called_with("add", testc2Path, match._)
      assert.spy(handler).called_with("add", testc3Path, match._)
      assert.spy(handler).called_with("add", testc4Path, match._)
      assert.spy(handler).called_with("add", testc5Path, match._)
      assert.spy(handler).called_with("add", testc6Path, match._)
      assert.spy(handler).called_with("add", testc7Path, match._)
      assert.spy(handler).called_with("add", testc8Path, match._)
      assert.spy(handler).called_with("add", testc9Path, match._)
      assert.spy(handler).called_with("add", testd1Path, match._)
      assert.spy(handler).called_with("add", teste1Path, match._)
      assert.spy(handler).called_with("add", testf1Path, match._)
      assert.spy(handler).called_with("add", testg1Path, match._)
      assert.spy(handler).called_with("add", testh1Path, match._)
      assert.spy(handler).called_with("add", testi1Path, match._)
    end)

    it("should emit `addDir` event when directory was added", function()
      local handler = spy.new()
      watcher = FS.watch(temp_dir, handler)

      wait_watcher_to_be_ready(watcher)

      local test_dir = Path.join(temp_dir, "subdir")

      FS.mkdir(test_dir)

      assert.is_true(wait_event(watcher, "add_dir"), "Expected 'add_dir' event for created directory")
      assert.spy(handler).called(1)
      assert.spy(handler).called_with("add_dir", test_dir, match._)
    end)

    it("should emit `change` event when file was changed", function()
      local test_path = get_fixture_path(temp_dir, "change.txt")

      FS.writefile(test_path, "test")

      local handler = spy.new()
      watcher = FS.watch(temp_dir, handler)

      wait_watcher_to_be_ready(watcher)

      assert.spy(handler).called(0)

      write_file(test_path, tostring(vim.uv.now()))

      assert.is_true(wait_event(watcher, "change"), "Expected 'change' event for created file")
      assert.spy(handler).called(1)
      assert.spy(handler).called_with("change", test_path, match._)
    end)

    it("should emit `unlink` event when file was removed", function()
      local test_path = get_fixture_path(temp_dir, "unlink.txt")

      FS.writefile(test_path, "test")

      local handler = spy.new()
      watcher = FS.watch(temp_dir, handler)

      wait_watcher_to_be_ready(watcher)

      assert.spy(handler).called(0)

      FS.rm(test_path)

      assert.is_true(wait_event(watcher, "unlink"), "Expected 'unlink' event for created file")
      assert.spy(handler).called(1)
      assert.spy(handler).called_with("unlink", test_path, match._)
    end)

    it("should emit `unlinkDir` event when a directory was removed", function()
      local test_dir = Path.join(temp_dir, "subdir")

      FS.mkdir(test_dir)

      local handler = spy.new()
      watcher = FS.watch(temp_dir, handler)

      wait_watcher_to_be_ready(watcher)

      assert.spy(handler).called(0)

      FS.rm(test_dir)

      assert.is_true(wait_event(watcher, "unlink_dir"), "Expected 'unlink_dir' event for created folder")
      assert.spy(handler).called(1)
      assert.spy(handler).called_with("unlink_dir", test_dir, match._)
    end)

    it("should emit two `unlinkDir` event when two nested directories were removed", function()
      local test_dir = get_fixture_path(temp_dir, "subdir")
      local test_dir2 = get_fixture_path(temp_dir, "subdir/subdir2")
      local test_dir3 = get_fixture_path(temp_dir, "subdir/subdir2/subdir3")

      FS.mkdir(test_dir)
      FS.mkdir(test_dir2)
      FS.mkdir(test_dir3)

      local handler = spy.new()
      watcher = FS.watch(temp_dir, { recursive = true }, handler)

      wait_watcher_to_be_ready(watcher)

      FS.rm(test_dir2, { recursive = true })

      assert.is_true(wait_event(watcher, "unlink_dir", 2), "Expected 'unlink_dir' event for created folder")
      assert.spy(handler).called(2)
      assert.spy(handler).called_with("unlink_dir", test_dir2, match._)
      assert.spy(handler).called_with("unlink_dir", test_dir3, match._)
    end)

    it("should emit `unlink` and `add` events when a file is renamed", function()
      local test_path = get_fixture_path(temp_dir, "change.txt")
      local new_path = get_fixture_path(temp_dir, "moved.txt")

      FS.writefile(test_path, "test")

      local handler = spy.new()
      watcher = FS.watch(temp_dir, handler)

      wait_watcher_to_be_ready(watcher)

      FS.rename(test_path, new_path)

      wait_event(watcher, "add")

      assert.spy(handler).called(2)
      assert.spy(handler).called_with("unlink", test_path, match._)
      assert.spy(handler).called_with("add", new_path, match._)
    end)

    it("should emit `add`, not `change`, when previously deleted file is re-added", function()
      local test_path = get_fixture_path(temp_dir, "add.txt")

      local handler = spy.new()
      watcher = FS.watch(temp_dir, handler)
      wait_watcher_to_be_ready(watcher)

      FS.writefile(test_path, "test")

      assert.is_true(wait_event(watcher, "add"), "Expected 'add' event for created file")
      assert.spy(handler).called(1)
      assert.spy(handler).called_with("add", test_path, match._)

      FS.rm(test_path)

      assert.is_true(wait_event(watcher, "unlink"), "Expected 'unlink' event for created file")
      assert.spy(handler).called(2)
      assert.spy(handler).called_with("unlink", test_path, match._)

      FS.writefile(test_path, tostring(vim.uv.now()))

      assert.is_true(wait_event(watcher, "add"), "Expected 'add' event for created file")
      assert.spy(handler).called(3)
      assert.spy(handler).called_with("add", test_path, match._)
      assert.spy(handler).was_not_called_with("change", test_path, match._)
    end)

    it("should not emit `unlink` for previously moved files", function()
      local test_path = get_fixture_path(temp_dir, "change.txt")
      local new_path1 = get_fixture_path(temp_dir, "moved.txt")
      local new_path2 = get_fixture_path(temp_dir, "moved-again.txt")

      FS.writefile(test_path, "test")

      local handler = spy.new()
      watcher = FS.watch(temp_dir, handler)
      wait_watcher_to_be_ready(watcher)

      FS.rename(test_path, new_path1)

      vim.wait(450) -- changed for a flaky test situation

      FS.rename(new_path1, new_path2)

      assert.is_true(wait_event(watcher, "unlink"), "Expected 'unlink' event for created file")

      assert.spy(handler).called(4)
      assert.spy(handler).called_with("unlink", test_path, match._)
      assert.spy(handler).called_with("add", new_path1, match._)
      assert.spy(handler).called_with("unlink", new_path1, match._)
      assert.spy(handler).called_with("add", new_path2, match._)
      assert.spy(handler).was_not_called_with("unlink", new_path2._, match._)
      assert.spy(handler).was_not_called_with("add", test_path, match._)
      assert.spy(handler).was_not_called_with("change", match._, match._)
    end)

    it("should notice when a file appears in a new directory", function()
      local test_dir = get_fixture_path(temp_dir, "subdir")
      local test_path = get_fixture_path(test_dir, "add.txt") -- NOTE: change

      local handler = spy.new()
      watcher = FS.watch(temp_dir, { recursive = true }, handler)
      wait_watcher_to_be_ready(watcher)

      FS.mkdir(test_dir)

      assert.is_true(wait_event(watcher, "add_dir"), "Expected 'add_dir' event for created file")
      vim.wait(200)

      FS.writefile(test_path, "test")

      assert.is_true(wait_event(watcher, "add"), "Expected 'add' event for created file")
      assert.spy(handler).called(2)
      assert.spy(handler).called_with("add_dir", test_dir, match._)
      assert.spy(handler).called_with("add", test_path, match._)
    end)

    it("should watch removed and re-added directories", function()
      local parent_path = get_fixture_path(temp_dir, "subdir2")
      local sub_path = get_fixture_path(temp_dir, "subdir2/subsub") -- NOTE: change
      local sub_file = get_fixture_path(sub_path, "somefile") -- NOTE: change

      local handler = spy.new()
      watcher = FS.watch(temp_dir, { recursive = true }, handler)
      wait_watcher_to_be_ready(watcher)

      FS.mkdir(parent_path)
      vim.wait(300)

      FS.rm(parent_path)

      assert.is_true(wait_event(watcher, "unlink_dir"), "Expected 'unlink_dir' event for created file")
      assert.spy(handler).called(2)
      assert.spy(handler).called_with("add_dir", parent_path, match._)
      assert.spy(handler).called_with("unlink_dir", parent_path, match._)

      FS.mkdir(parent_path)
      vim.wait(2200)

      FS.mkdir(sub_path)

      assert.is_true(wait_event(watcher, "add_dir"), "Expected 'add_dir' event for created file")
      assert.spy(handler).called(4)
      assert.spy(handler).called_with("add_dir", sub_path, match._)

      vim.wait(300)
      FS.writefile(sub_file, "test")

      assert.is_true(wait_event(watcher, "add"), "Expected 'add' event for created file")
      assert.spy(handler).called(5)
      assert.spy(handler).called_with("add", sub_file, match._)
      assert.spy(handler).was_not_called_with("add", parent_path, match._)
      assert.spy(handler).was_not_called_with("add", sub_path, match._)
    end)

    it("should emit `unlinkDir` and `add` when dir is replaced by file", function()
      local test_path = get_fixture_path(temp_dir, "dir_file")

      FS.mkdir(test_path)
      vim.wait(300)

      local handler = spy.new()
      watcher = FS.watch(temp_dir, handler)
      wait_watcher_to_be_ready(watcher)

      FS.rm(test_path)

      assert.is_true(wait_event(watcher, "unlink_dir"), "Expected 'unlink_dir' event for created directory")
      assert.spy(handler).called(1)
      assert.spy(handler).called_with("unlink_dir", test_path, match._)

      FS.writefile(test_path, "file content")

      assert.is_true(wait_event(watcher, "add"), "Expected 'add' event for created file")
      assert.spy(handler).called(2)
      assert.spy(handler).called_with("unlink_dir", test_path, match._)
      assert.spy(handler).called_with("add", test_path, match._)
      assert.spy(handler).was_not_called_with("add_dir", sub_path, match._)
    end)

    it("should emit `unlink` and `addDir` when file is replaced by dir", function()
      local test_path = get_fixture_path(temp_dir, "dir_file")

      FS.writefile(test_path, "file content")

      local handler = spy.new()
      watcher = FS.watch(temp_dir, handler)
      wait_watcher_to_be_ready(watcher)

      FS.rm(test_path)

      vim.wait(300)

      FS.mkdir(test_path)

      assert.is_true(wait_event(watcher, "add_dir"), "Expected 'add' event for created file")
      assert.spy(handler).called(2)
      assert.spy(handler).called_with("unlink", test_path, match._)
      assert.spy(handler).called_with("add_dir", test_path, match._)
    end)

    it("renaming a folder works correctly", function()
      local test_path = get_fixture_path(temp_dir, "dir_file")
      local new_path = get_fixture_path(temp_dir, "new_dir")

      FS.mkdir(test_path)

      local handler = spy.new()
      watcher = FS.watch(temp_dir, handler)
      wait_watcher_to_be_ready(watcher)

      FS.rename(test_path, new_path)

      assert.is_true(wait_event(watcher, "add_dir"), "Expected 'add' event for created dir")
      assert.spy(handler).called(2)
      assert.spy(handler).called_with("unlink_dir", test_path, match._)
      assert.spy(handler).called_with("add_dir", new_path, match._)
    end)
  end)

  describe("watch individual files", function()
    it("should detect changes", function()
      local test_path = get_fixture_path(temp_dir, "change.txt")

      FS.writefile(test_path, "something")

      local handler = spy.new()
      watcher = FS.watch(test_path, handler)
      wait_watcher_to_be_ready(watcher)

      FS.appendfile(test_path, " adding smt")

      assert.is_true(wait_event(watcher, "change"), "Expected 'change' event for created file")
      assert.spy(handler).called(1)
      assert.spy(handler).called_with("change", test_path, match._)
    end)

    it("should detect unlinks", function()
      local test_path = get_fixture_path(temp_dir, "unlink.txt")

      FS.writefile(test_path, "test")

      local handler = spy.new()
      watcher = FS.watch(test_path, handler)
      wait_watcher_to_be_ready(watcher)

      FS.rm(test_path)

      assert.is_true(wait_event(watcher, "unlink"), "Expected 'unlink' event for created file")
      assert.spy(handler).called(1)
      assert.spy(handler).called_with("unlink", test_path, match._)
    end)

    it("should detect unlink and detect re-add", function()
      local test_path = get_fixture_path(temp_dir, "unlink.txt")

      FS.writefile(test_path, "test")

      local handler = spy.new()
      watcher = FS.watch(test_path, handler)
      wait_watcher_to_be_ready(watcher)

      FS.rm(test_path)

      assert.is_true(wait_event(watcher, "unlink"), "Expected 'unlink' event for created file")
      assert.spy(handler).called(1)
      assert.spy(handler).called_with("unlink", test_path, match._)

      vim.wait(200)
      FS.writefile(test_path, "something")

      assert.is_true(wait_event(watcher, "add"), "Expected 'add' event for created file")
      assert.spy(handler).called(2)
      assert.spy(handler).called_with("add", test_path, match._)
    end)

    it("should ignore unwatched siblings", function()
      local test_path = get_fixture_path(temp_dir, "add.txt")
      local sibling_path = get_fixture_path(temp_dir, "change.txt")

      local handler = spy.new()
      watcher = FS.watch(test_path, handler)

      vim.wait(300)

      FS.writefile(test_path, "asdasd")
      FS.writefile(sibling_path, " nanana")

      vim.wait(200)

      assert.spy(handler).called(1)
      assert.spy(handler).called_with("add", test_path, match._)
    end)

    it("should detect safe-edit", function()
      local test_path = get_fixture_path(temp_dir, "change.txt")
      local safe_path = get_fixture_path(temp_dir, "tmp.txt")

      FS.writefile(test_path, "test")

      local handler = spy.new()
      watcher = FS.watch(test_path, handler)
      wait_watcher_to_be_ready(watcher)

      wait(200)
      FS.appendfile(safe_path, " first")
      FS.rename(safe_path, test_path)

      wait(300)

      FS.writefile(safe_path, "last_add")
      FS.rename(safe_path, test_path)

      wait(300)

      FS.writefile(safe_path, "next_add")
      FS.rename(safe_path, test_path)

      wait(300)

      FS.appendfile(safe_path, "nana")

      wait(300)

      assert.spy(handler).called(3)
      assert.spy(handler).called_with("change", test_path, match._)
      assert.spy(handler).was_not_called_with("add", sub_path, match._)
      assert.spy(handler).was_not_called_with("unlink", sub_path, match._)
      assert.spy(handler).was_not_called_with("add_dir", sub_path, match._)
      assert.spy(handler).was_not_called_with("unlink_dir", sub_path, match._)
    end)

    describe("gh-682 should detect unlink then re-adds", function()
      -- NOTE: Fix nil lookup and revert this test case to previous version
      it("should detect unlink while watching a non-existent second file in another directory", function()
        local test_path = get_fixture_path(temp_dir, "unlink.txt")
        local other_dir_path = get_fixture_path(temp_dir, "other-dir")

        FS.writefile(test_path, "test")
        FS.mkdir(other_dir_path)

        local handler = spy.new()
        watcher = FS.watch({ test_path, other_dir_path }, handler)

        wait(300)
        -- intentionally for this test don't write fs.writeFileSync(otherPath, 'other');

        FS.rm(test_path)

        assert.is_true(wait_event(watcher, "unlink"), "Expected 'unlink' event for created file")
        assert.spy(handler).called(1)
        assert.spy(handler).called_with("unlink", test_path, nil)
      end)

      it("should detect unlink and re-add while watching a second file", function()
        -- options.ignoreInitial = true;
        local test_path = get_fixture_path(temp_dir, "unlink.txt")
        local other_path = get_fixture_path(temp_dir, "other.txt")

        FS.writefile(other_path, "something")
        FS.writefile(test_path, "something")

        _G.DEBUG = true

        local handler = spy.new()
        watcher = FS.watch(test_path, handler)

        wait(300)

        FS.rm(test_path)

        assert.is_true(wait_event(watcher, "unlink"), "Expected 'unlink' event for created file")
        assert.spy(handler).called(1)
        assert.spy(handler).called_with("unlink", test_path, nil)

        wait(300)

        FS.writefile(test_path, "re-added")

        wait(300)

        -- NOTE: this doesnt work, watcher changes or doesnt get the add
        -- assert.is_true(wait_event(watcher, "add", 3000), "Expected 'add' event for created file")
        assert.spy(handler).called(2)
        assert.spy(handler).called_with("add", test_path, match._)
      end)

      --  TODO: causes a problem in entire test suite
      it("should detect unlink and re-add while watching a non-existent second file in another directory", function()
        local test_path = get_fixture_path(temp_dir, "unlink.txt")
        local other_dir_path = get_fixture_path(temp_dir, "other-dir")
        local other_path = get_fixture_path(other_dir_path, "other.txt")

        FS.writefile(test_path, "something")
        FS.mkdir(other_dir_path)

        local handler = spy.new()
        watcher = FS.watch({ test_path, other_path }, handler)

        wait(300)

        FS.rm(test_path)

        assert.is_true(wait_event(watcher, "unlink"), "Expected 'unlink' event for created file")
        assert.spy(handler).called(1)

        wait(300) -- This fixes the test case

        FS.writefile(test_path, "re-added")

        assert.is_true(wait_event(watcher, "add"), "Expected 'add' event for created file")
        assert.spy(handler).called(2)
        assert.spy(handler).called_with("add", test_path, match._)
      end)

      it("should detect unlink and re-add while watching a non-existent second file in the same directory", function()
        local test_path = get_fixture_path(temp_dir, "unlink.txt")
        local other_path = get_fixture_path(temp_dir, "other.txt")

        FS.writefile(test_path, "something")
        -- FS.writefile(other_path, "other something")

        local handler = spy.new()
        watcher = FS.watch({ test_path, other_path }, handler)

        wait(300)

        FS.rm(test_path)

        assert.is_true(wait_event(watcher, "unlink"), "Expected 'unlink' event for created file")
        assert.spy(handler).called(1)
        assert.spy(handler).called_with("unlink", test_path, nil)

        wait(300)

        FS.writefile(test_path, "re-added")

        assert.is_true(wait_event(watcher, "add"), "Expected 'add' event for created file")
        assert.spy(handler).called(2)
        assert.spy(handler).called_with("add", test_path, match._)
      end)

      -- NOTE: Adjustments start from here
      it("should detect two unlinks and one re-add", function()
        local test_path = get_fixture_path(temp_dir, "unlink.txt")
        local other_path = get_fixture_path(temp_dir, "other.txt")

        FS.writefile(test_path, "something")
        FS.writefile(other_path, "other something")

        local handler = spy.new()
        watcher = FS.watch({ test_path, other_path }, handler)

        wait(300)

        FS.rm(other_path)

        assert.is_true(wait_event(watcher, "unlink"), "Expected 'unlink' event for created file")
        assert.spy(handler).called(1)
        assert.spy(handler).called_with("unlink", other_path, nil)

        FS.rm(test_path)

        assert.is_true(wait_event(watcher, "unlink"), "Expected 'unlink' event for created file")
        assert.spy(handler).called(2)
        assert.spy(handler).called_with("unlink", test_path, nil)

        wait(300)

        FS.writefile(test_path, "re-added")

        assert.is_true(wait_event(watcher, "add"), "Expected 'add' event for created file")
        assert.spy(handler).called(3)
        assert.spy(handler).called_with("add", test_path, match._)
      end)

      it("should detect unlink and re-add while watching a second file and a non-existent third file", function()
        local test_path = get_fixture_path(temp_dir, "unlink.txt")
        local other_path = get_fixture_path(temp_dir, "other.txt")
        local other_path2 = get_fixture_path(temp_dir, "other2.txt")

        FS.writefile(test_path, "something")
        FS.writefile(other_path, "other something")

        local handler = spy.new()
        watcher = FS.watch({ test_path, other_path, other_path2 }, handler)

        wait(300)

        FS.rm(test_path)

        assert.is_true(wait_event(watcher, "unlink"), "Expected 'unlink' event for created file")
        assert.spy(handler).called(1)
        assert.spy(handler).called_with("unlink", test_path, nil)

        wait(300)

        FS.writefile(test_path, "re-added")

        assert.is_true(wait_event(watcher, "add"), "Expected 'add' event for created file")
        assert.spy(handler).called(2)
        assert.spy(handler).called_with("add", test_path, match._)
      end)
    end)
  end)

  describe("renamed directory", function()
    it("should emit `add` for a file in a renamed directory", function()
      local test_dir = get_fixture_path(temp_dir, "subdir")
      local test_path = get_fixture_path(test_dir, "add.txt")
      local renamed_dir = get_fixture_path(temp_dir, "subdir-renamed")

      local expected_path = get_fixture_path(renamed_dir, "add.txt")

      FS.mkdir(test_dir)

      FS.writefile(test_path, "something")

      local handler = spy.new()
      watcher = FS.watch(temp_dir, handler)

      wait(1000) -- instead wait ready, reduce it!

      FS.rename(test_dir, renamed_dir)

      assert.is_true(wait_event(watcher, "unlink_dir"), "Expected 'unlink' event for created folder")
      assert.spy(handler).called(2)
      assert.spy(handler).called_with("unlink_dir", test_dir, nil)
      assert.spy(handler).called_with("add_dir", renamed_dir, match._)
      -- TODO: Chokidar fires these events, I fire less:
      -- assert.spy(handler).called_with("unlink", test_path, match._)
      -- assert.spy(handler).called_with("add", expected_path, nil)
    end)
  end)

  describe("watch non-existent paths", function()
    it("should watch non-existent file and detect add", function()
      local test_path = get_fixture_path(temp_dir, "add.txt")

      local handler = spy.new()
      watcher = FS.watch(test_path, handler)

      wait(300)

      FS.writefile(test_path, "something")

      assert.is_true(wait_event(watcher, "add"), "Expected 'unlink' event for created folder")
      assert.spy(handler).called(1)
      assert.spy(handler).called_with("add", test_path, match._)
    end)

    it("should watch non-existent dir and detect addDir/add", function()
      local test_dir = get_fixture_path(temp_dir, "subdir")
      local test_path = get_fixture_path(test_dir, "add.txt")

      local handler = spy.new()
      watcher = FS.watch(test_dir, handler)

      wait(300)

      FS.mkdir(test_dir)

      assert.is_true(wait_event(watcher, "add_dir"), "Expected 'add_dir' event for created folder")
      assert.spy(handler).called(1)
      assert.spy(handler).called_with("add_dir", test_dir, match._)

      wait(300)

      FS.writefile(test_path, "cool")

      assert.is_true(wait_event(watcher, "add"), "Expected 'add' event for created file")
      assert.spy(handler).called(2)
      assert.spy(handler).called_with("add", test_path, match._)
    end)
  end)

  describe("watch symlinks", function()
    it("should watch symlinked dirs", function()
      local sub_dir = get_fixture_path(temp_dir, "subdir")
      local linked_dir = get_fixture_path(temp_dir, "linked-1")
      local change_path = get_fixture_path(sub_dir, "change.txt")
      local unlink_path = get_fixture_path(sub_dir, "unlink.txt")

      FS.mkdir(sub_dir)
      FS.writefile(change_path, "something")
      FS.writefile(unlink_path, "another thing")

      local handler = spy.new()
      watcher = FS.watch(linked_dir, handler)

      wait(300)

      FS.symlink(sub_dir, linked_dir)

      wait(300)

      assert.spy(handler).called(1)
      assert.spy(handler).called_with("add_dir", linked_dir, match._)
      -- NOTE: On chokidar, events traverse down the directories:
      -- assert.spy(handler).called_with("add", change_path, match._)
      -- assert.spy(handler).called_with("add", unlink_path, match._)
    end)

    it("should watch symlinked files", function()
      local change_path = get_fixture_path(temp_dir, "change.txt")
      local link_path = get_fixture_path(temp_dir, "link.txt")

      FS.writefile(change_path, "something")
      FS.symlink(change_path, link_path)

      local handler = spy.new()
      watcher = FS.watch(link_path, handler)

      wait(300)

      FS.appendfile(change_path, "adding something")

      assert.is_true(wait_event(watcher, "change"), "Expected 'change' event for created file")
      assert.spy(handler).called(1)
      assert.spy(handler).called_with("change", link_path, match._)
    end)

    -- TODO: This one is buggy, FIX THIS!:
    -- it("should follow symlinked files within a normal dir", function()
    --   local change_path = get_fixture_path(temp_dir, "change.txt")
    --   local sub_dir = get_fixture_path(temp_dir, "subdir")
    --   local link_path = get_fixture_path(sub_dir, "link.txt")
    --
    --   FS.mkdir(sub_dir) -- NOTE: remove this
    --   FS.writefile(change_path, "something")
    --   FS.symlink(change_path, link_path)
    --
    --   wait(300)
    --
    --   local handler = spy.new()
    --   watcher = FS.watch(sub_dir, handler)
    --
    --   wait(300)
    --   -- FS.symlink(change_path, link_path) -- NOTE: This fires up an event
    --
    --   wait(1000)
    --
    --   FS.appendfile(change_path, "adding something") -- NOTE: This doesn't fire symlinks
    --
    --   wait(300)
    --
    --   -- assert.is_true(wait_event(watcher, "change"), "Expected 'change' event for created file")
    --   assert.spy(handler).called(1)
    --   assert.spy(handler).called_with("change", link_path, match._)
    -- end)

    -- it('should watch paths with a symlinked parent', async () => {
    --   const testDir = sysPath.join(linkedDir, 'subdir');
    --   const testFile = sysPath.join(testDir, 'add.txt');
    --   const watcher = chokidar_watch(testDir, options);
    --   const spy = await aspy(watcher, EV.ALL);
    --
    --   spy.should.have.been.calledWith(EV.ADD_DIR, testDir);
    --   spy.should.have.been.calledWith(EV.ADD, testFile);
    --   await write(getFixturePath('subdir/add.txt'), dateNow());
    --   await waitFor([spy.withArgs(EV.CHANGE)]);
    --   spy.should.have.been.calledWith(EV.CHANGE, testFile);
    -- });

    -- it('should not recurse indefinitely on circular symlinks', async () => {
    --   await fs_symlink(currentDir, getFixturePath('subdir/circular'), isWindows ? 'dir' : null);
    --   return new Promise((resolve, reject) => {
    --     const watcher = chokidar_watch(currentDir, options);
    --     watcher.on(EV.ERROR, resolve());
    --     watcher.on(EV.READY, reject('The watcher becomes ready, although he watches a circular symlink.'));
    --   })
    -- });

    -- it('should recognize changes following symlinked dirs', async () => {
    --   const linkedFilePath = sysPath.join(linkedDir, 'change.txt');
    --   const watcher = chokidar_watch(linkedDir, options);
    --   const spy = await aspy(watcher, EV.CHANGE);
    --   const wa = spy.withArgs(linkedFilePath);
    --   await write(getFixturePath('change.txt'), dateNow());
    --   await waitFor([wa]);
    --   spy.should.have.been.calledWith(linkedFilePath);
    -- });

    -- it('should follow newly created symlinks', async () => {
    --   options.ignoreInitial = true;
    --   const watcher = chokidar_watch(currentDir, options);
    --   const spy = await aspy(watcher, EV.ALL);
    --   await delay();
    --   await fs_symlink(getFixturePath('subdir'), getFixturePath('link'), isWindows ? 'dir' : null);
    --   await waitFor([
    --     spy.withArgs(EV.ADD, getFixturePath('link/add.txt')),
    --     spy.withArgs(EV.ADD_DIR, getFixturePath('link'))
    --   ]);
    --   spy.should.have.been.calledWith(EV.ADD_DIR, getFixturePath('link'));
    --   spy.should.have.been.calledWith(EV.ADD, getFixturePath('link/add.txt'));
    -- });

    -- it('should watch symlinks as files when followSymlinks:false', async () => {
    --   options.followSymlinks = false;
    --   const watcher = chokidar_watch(linkedDir, options);
    --   const spy = await aspy(watcher, EV.ALL);
    --   spy.should.not.have.been.calledWith(EV.ADD_DIR);
    --   spy.should.have.been.calledWith(EV.ADD, linkedDir);
    --   spy.should.have.been.calledOnce;
    -- });

    -- it('should survive ENOENT for missing symlinks when followSymlinks:false', async () => {
    --   options.followSymlinks = false;
    --   const targetDir = getFixturePath('subdir/nonexistent');
    --   await fs_mkdir(targetDir);
    --   await fs_symlink(targetDir, getFixturePath('subdir/broken'), isWindows ? 'dir' : null);
    --   await fs_rmdir(targetDir);
    --   await delay();
    --
    --   const watcher = chokidar_watch(getFixturePath('subdir'), options);
    --   const spy = await aspy(watcher, EV.ALL);
    --
    --   spy.should.have.been.calledTwice;
    --   spy.should.have.been.calledWith(EV.ADD_DIR, getFixturePath('subdir'));
    --   spy.should.have.been.calledWith(EV.ADD, getFixturePath('subdir/add.txt'));
    -- });

    -- it('should watch symlinks within a watched dir as files when followSymlinks:false', async () => {
    --   options.followSymlinks = false;
    --   // Create symlink in linkPath
    --   const linkPath = getFixturePath('link');
    --   fs.symlinkSync(getFixturePath('subdir'), linkPath);
    --   const spy = await aspy(chokidar_watch(currentDir, options), EV.ALL);
    --   await delay(300);
    --   setTimeout(() => {
    --     fs.writeFileSync(getFixturePath('subdir/add.txt'), dateNow());
    --     fs.unlinkSync(linkPath);
    --     fs.symlinkSync(getFixturePath('subdir/add.txt'), linkPath);
    --   }, options.usePolling ? 1200 : 300);
    --
    --   await delay(300);
    --   await waitFor([spy.withArgs(EV.CHANGE, linkPath)]);
    --   spy.should.not.have.been.calledWith(EV.ADD_DIR, linkPath);
    --   spy.should.not.have.been.calledWith(EV.ADD, getFixturePath('link/add.txt'));
    --   spy.should.have.been.calledWith(EV.ADD, linkPath);
    --   spy.should.have.been.calledWith(EV.CHANGE, linkPath);
    -- });

    -- it('should not reuse watcher when following a symlink to elsewhere', async () => {
    --   const linkedPath = getFixturePath('outside');
    --   const linkedFilePath = sysPath.join(linkedPath, 'text.txt');
    --   const linkPath = getFixturePath('subdir/subsub');
    --   fs.mkdirSync(linkedPath, PERM_ARR);
    --   fs.writeFileSync(linkedFilePath, 'b');
    --   fs.symlinkSync(linkedPath, linkPath);
    --   const watcher2 = chokidar_watch(getFixturePath('subdir'), options);
    --   await waitForWatcher(watcher2);
    --
    --   await delay(options.usePolling ? 900 : undefined);
    --   const watchedPath = getFixturePath('subdir/subsub/text.txt');
    --   const watcher = chokidar_watch(watchedPath, options);
    --   const spy = await aspy(watcher, EV.ALL);
    --
    --   await delay();
    --   await write(linkedFilePath, dateNow());
    --   await waitFor([spy.withArgs(EV.CHANGE)]);
    --   spy.should.have.been.calledWith(EV.CHANGE, watchedPath);
    -- });

    -- it('should emit ready event even when broken symlinks are encountered', async () => {
    --   const targetDir = getFixturePath('subdir/nonexistent');
    --   await fs_mkdir(targetDir);
    --   await fs_symlink(targetDir, getFixturePath('subdir/broken'), isWindows ? 'dir' : null);
    --   await fs_rmdir(targetDir);
    --   const readySpy = sinon.spy(function readySpy() { });
    --   const watcher = chokidar_watch(getFixturePath('subdir'), options)
    --     .on(EV.READY, readySpy);
    --   await waitForWatcher(watcher);
    --   readySpy.should.have.been.calledOnce;
    -- });
  end)
end)

-- Changing a folder and changing a file triggers
-- NOTE: Missing: symlinks, watch arrays of paths/globs, cwd
-- TODO: IN FUTURE: options.ignore, options.depth, options.dotfiles(?), options.ignorePermissionErrors(?), maybe watcher.readdir(watcher.getWatched()), maybe polling(?)
-- -- READ TEST SUITE: awaitWriteFinish, bug reproduction parts, close(!!), unwatch(!!)
