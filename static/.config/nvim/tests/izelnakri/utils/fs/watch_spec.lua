-- NOTE: rename folder test case maybe needed
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

    vim.wait(300)

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
    watcher = FS.watch(temp_dir, handler)
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
    watcher = FS.watch(temp_dir, handler)
    wait_watcher_to_be_ready(watcher)

    FS.mkdir(parent_path)
    vim.wait(300)

    FS.rm(parent_path)

    assert.is_true(wait_event(watcher, "unlink_dir"), "Expected 'unlink_dir' event for created file")
    assert.spy(handler).called(2)
    assert.spy(handler).called_with("add_dir", parent_path, match._)
    assert.spy(handler).called_with("unlink_dir", parent_path, match._)

    FS.mkdir(parent_path)
    vim.wait(1200)

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
end)
