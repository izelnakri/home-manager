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

local function wait_event(watcher, expected_event, timeout)
  local should_pass = false
  local last_event
  watcher:add_callback(function(event, path, stat)
    last_event = event
    if _G.DEBUG then
      vim.print("CALLBACK CALLED:")
      vim.print(vim.inspect(event), path)
      vim.print(vim.inspect(stat))
    end
    if event == expected_event then
      should_pass = true
    end
  end)
  vim.wait(timeout or DEFAULT_TIMEOUT, function()
    return should_pass
  end)
  if not should_pass then
    error("wait_event(watcher, " .. expected_event .. ") instead last event was: " .. tostring(last_event))
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

  vim.wait(timeout or 500, function()
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
    -- NOTE: Do I need watcher close(?)
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

  -- it('should emit `change` event when file was changed', async () => {
  --   const testPath = getFixturePath('change.txt');
  --   const spy = sinon.spy(function changeSpy(){});
  --   watcher.on(EV.CHANGE, spy);
  --   spy.should.not.have.been.called;
  --   await write(testPath, dateNow());
  --   await waitFor([spy]);
  --   spy.should.have.been.calledWith(testPath);
  --   expect(spy.args[0][1]).to.be.ok; // stats
  --   rawSpy.should.have.been.called;
  --   spy.should.have.been.calledOnce;
  -- });

  -- it("should emit `change` event when a file is modified", function()
  --   local test_path = Path.join(temp_dir, "change.txt")
  --   create_file(test_path)
  --
  --   watcher = FS.watch(temp_dir, { recursive = false })
  --   create_file(test_path, "modified content")
  --
  --   local triggered = wait_event(watcher, "modify")
  --   assert.is_true(triggered, "Expected 'change' event for modified file")
  -- end)

  -- it("should emit `remove` event when a file is deleted", function()
  --   local test_path = Path.join(temp_dir, "remove.txt")
  --   create_file(test_path)
  --
  --   watcher = FS.watch(temp_dir, { recursive = false })
  --   uv.fs_unlink(test_path)
  --
  --   local triggered = wait_event(watcher, "remove")
  --   assert.is_true(triggered, "Expected 'remove' event for deleted file")
  -- end)
  --
  -- it("should emit `unlinkDir` event when a directory is removed", function()
  --   local sub_dir = Path.join(temp_dir, "subdir")
  --   FS.mkdir(sub_dir)
  --
  --   watcher = FS.watch(temp_dir, { recursive = true })
  --   uv.fs_rmdir(sub_dir)
  --
  --   local triggered = wait_event(watcher, "remove")
  --   assert.is_true(triggered, "Expected 'unlinkDir' event for removed directory")
  -- end)
  --
  -- it("should emit `add` and `remove` events when a file is renamed", function()
  --   local file_path = Path.join(temp_dir, "rename.txt")
  --   local new_path = Path.join(temp_dir, "renamed.txt")
  --   create_file(file_path)
  --
  --   watcher = FS.watch(temp_dir, { recursive = false })
  --   uv.fs_rename(file_path, new_path)
  --
  --   local unlink_triggered = wait_event(watcher, "remove")
  --   local add_triggered = wait_event(watcher, "create")
  --
  --   assert.is_true(unlink_triggered, "Expected 'remove' event for renamed file")
  --   assert.is_true(add_triggered, "Expected 'add' event for renamed file")
  -- end)
  --
  -- it("should emit `addDir` event when a new directory is created", function()
  --   local sub_dir = Path.join(temp_dir, "new_subdir")
  --
  --   watcher = FS.watch(temp_dir, { recursive = false })
  --   FS.mkdir(sub_dir)
  --
  --   local triggered = wait_event(watcher, "create")
  --   assert.is_true(triggered, "Expected 'addDir' event for created directory")
  -- end)
  --
  -- it("should recursively watch directories and emit events for nested files", function()
  --   local sub_dir = Path.join(temp_dir, "subdir")
  --   FS.mkdir(sub_dir)
  --
  --   watcher = FS.watch(temp_dir, { recursive = true })
  --   local file_in_subdir = Path.join(sub_dir, "nested_file.txt")
  --   create_file(file_in_subdir)
  --
  --   local triggered = wait_event(watcher, "create")
  --   assert.is_true(triggered, "Expected 'add' event for file in subdirectory")
  -- end)
  --
  -- it("should detect and handle symlinked files", function()
  --   local original_file = Path.join(temp_dir, "original.txt")
  --   local symlink_file = Path.join(temp_dir, "symlink.txt")
  --   create_file(original_file)
  --   uv.fs_symlink(original_file, symlink_file)
  --
  --   watcher = FS.watch(temp_dir, { recursive = false })
  --   create_file(original_file, "updated content")
  --
  --   local triggered = wait_event(watcher, "modify")
  --   assert.is_true(triggered, "Expected 'change' event for symlinked file")
  -- end)
  --
  -- it("should handle multiple `unlinkDir` events when nested directories are removed", function()
  --   local dir1 = Path.join(temp_dir, "dir1")
  --   local dir2 = Path.join(dir1, "dir2")
  --   FS.mkdir(dir1)
  --   FS.mkdir(dir2)
  --
  --   watcher = FS.watch(temp_dir, { recursive = true })
  --   uv.fs_rmdir(dir2)
  --   uv.fs_rmdir(dir1)
  --
  --   local triggered = wait_event(watcher, "remove")
  --   assert.is_true(triggered, "Expected 'unlinkDir' events for removed directories")
  -- end)
  -- end)

  -- describe("FS.watch", function()
  --   describe('watch a directory', function()
  --     -- beforeEach(async () => {
  --     --   options.ignoreInitial = true;
  --     --   options.alwaysStat = true;
  --     --   readySpy = sinon.spy(function readySpy(){});
  --     --   rawSpy = sinon.spy(function rawSpy(){});
  --     --   watcher = chokidar_watch(currentDir, options).on(EV.READY, readySpy).on(EV.RAW, rawSpy);
  --     --   await waitForWatcher(watcher);
  --     -- });
  --     -- afterEach(async () => {
  --     --   await waitFor([readySpy]);
  --     --   await watcher.close();
  --     --   readySpy.should.have.been.calledOnce;
  --     --   readySpy = undefined;
  --     --   rawSpy = undefined;
  --     -- });
  --
  --     it('should emit `add` event when file was added', function
  --       local testPath = get_fixture_path(temp_dir, 'add.txt');
  --
  --       local spy = sinon.spy(function addSpy(){});
  --
  --       watcher.on(EV.ADD, spy);
  --
  --       await delay();
  --       await write(testPath, dateNow());
  --       await waitFor([spy]);
  --
  --       spy.should.have.been.calledOnce;
  --       assert.spy(handler).called_with(testPath);
  --       expect(spy.args[0][1]).to.be.ok; // stats
  --
  --       rawSpy.should.have.been.called;
  --
  --     });
  --
  --   end)
  -- end)

  -- describe("FS.watch", function()
  --   local tmpdir = "test_dir"
  --   local testfile = tmpdir .. "/test_file.txt"
  --   local testdir = tmpdir .. "/test_subdir"
  --   local callback_called, event_triggered, filenames
  --
  --   before_each(function()
  --     callback_called = false
  --     event_triggered = {}
  --     filenames = {}
  --
  --     -- Create test directory and file
  --     uv.fs_mkdir(tmpdir, 448)
  --     local fd = uv.fs_open(testfile, "w", 438)
  --     uv.fs_close(fd)
  --   end)
  --
  --   after_each(function()
  --     -- Clean up
  --     FS.unwatch(tmpdir)
  --     FS.unwatch(testfile)
  --     FS.rm(tmpdir, { recursive = true })
  --   end)
  --
  --   it("should trigger callback for file add, change, and remove events", function()
  --     local watcher = FS.watch(tmpdir, function(event, filename)
  --       callback_called = true
  --       table.insert(event_triggered, event)
  --       table.insert(filenames, filename)
  --     end)
  --
  --     -- Simulate file addition
  --     local newfile = tmpdir .. "/newfile.txt"
  --     local fd = uv.fs_open(newfile, "w", 438)
  --     uv.fs_close(fd)
  --     uv.fs_unlink(newfile)
  --     vim.wait(200) -- Give some time for events to trigger
  --     assert.are.same(event_triggered[1], "create")
  --     assert.are.same(filenames[1], "newfile.txt")
  --
  --     -- Simulate file change
  --     fd = uv.fs_open(testfile, "a", 438)
  --     uv.fs_write(fd, "test content", -1)
  --     uv.fs_close(fd)
  --     vim.wait(200)
  --     assert.are.same(event_triggered[2], "change")
  --     assert.are.same(filenames[2], "test_file.txt")
  --
  --     -- Simulate file removal
  --     uv.fs_unlink(testfile)
  --     vim.wait(200)
  --     assert.are.same(event_triggered[3], "delete")
  --     assert.are.same(filenames[3], "test_file.txt")
  --
  --     -- Ensure callback was called each time
  --     assert.is_true(callback_called)
  --   end)

  -- it("should trigger callback for directory add and remove events", function()
  --   local watcher = FS.watch(tmpdir, function(event, filename)
  --     callback_called = true
  --     table.insert(event_triggered, event)
  --     table.insert(filenames, filename)
  --   end)
  --
  --   -- Simulate directory addition
  --   uv.fs_mkdir(testdir, 448)
  --   vim.wait(200)
  --   assert.are.same(event_triggered[1], "create")
  --   assert.are.same(filenames[1], "test_subdir")
  --
  --   -- Simulate directory removal
  --   uv.fs_rmdir(testdir)
  --   vim.wait(200)
  --   assert.are.same(event_triggered[2], "delete")
  --   assert.are.same(filenames[2], "test_subdir")
  --
  --   -- Ensure callback was called for both events
  --   assert.is_true(callback_called)
  -- end)
  --
  -- it("should stop triggering events after unwatch is called", function()
  --   local watcher = FS.watch(tmpdir, function(event, filename)
  --     callback_called = true
  --   end)
  --
  --   -- Unwatch the directory
  --   FS.unwatch(tmpdir)
  --
  --   -- Simulate an event
  --   uv.fs_mkdir(testdir, 448)
  --   vim.wait(200)
  --
  --   -- Ensure callback was NOT called after unwatch
  --   assert.is_false(callback_called)
  --
  --   -- Clean up
  --   uv.fs_rmdir(testdir)
  -- end)
  --
  -- it("should allow two watches on the same path, unwatching only stops one", function()
  --   local callback_called_1, callback_called_2 = false, false
  --
  --   local watcher1 = FS.watch(tmpdir, function(event, filename)
  --     callback_called_1 = true
  --   end)
  --
  --   local watcher2 = FS.watch(tmpdir, function(event, filename)
  --     callback_called_2 = true
  --   end)
  --
  --   -- Unwatch only the first watcher
  --   FS.unwatch(watcher1)
  --
  --   -- Trigger an event
  --   uv.fs_mkdir(testdir, 448)
  --   vim.wait(200)
  --
  --   -- Only the second watcher should be called
  --   assert.is_false(callback_called_1)
  --   assert.is_true(callback_called_2)
  --
  --   -- Clean up
  --   FS.unwatch(watcher2)
  --   uv.fs_rmdir(testdir)
  -- end)
  --
  -- it("should ensure no event is triggered if no event happens and path is unwatched", function()
  --   local watcher = FS.watch(tmpdir, function(event, filename)
  --     callback_called = true
  --   end)
  --
  --   -- Unwatch the directory before any events are triggered
  --   FS.unwatch(tmpdir)
  --
  --   -- Wait for a bit to ensure no event happens
  --   vim.wait(200)
  --
  --   -- Ensure no callback was called since no events occurred
  --   assert.is_false(callback_called)
  -- end)
end)
