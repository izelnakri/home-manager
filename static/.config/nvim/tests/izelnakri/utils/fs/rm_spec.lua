local Path = require("izelnakri.utils.path")
local List = require("izelnakri.utils.list")

local uv = vim.uv
local FS = require("izelnakri.utils.fs")

local function create_temp_dir()
  local tmp_dir = Path.join(os.tmpname())
  -- os.tmpname() may create a file; ensure it's a directory
  os.remove(tmp_dir)
  local success, err = FS.mkdir(tmp_dir)
  assert.is_true(success, "Failed to create temp directory: " .. tostring(err))
  return tmp_dir
end

local function directory_exists(dir_path)
  local stat = uv.fs_stat(dir_path)
  return (stat and stat.type == "directory") or false
end

local function file_exists(file_path)
  local stat = uv.fs_stat(file_path)
  return (stat and stat.type == "file") or false
end

describe("FS.rm (sync)", function()
  local temp_dir

  before_each(function()
    temp_dir = create_temp_dir()
  end)

  after_each(function()
    -- Cleanup: Remove temp_dir if it still exists
    if directory_exists(temp_dir) then
      local success, err = FS.rm(temp_dir, { recursive = true })
      if not success then
        io.stderr:write("Failed to clean up temp_dir: " .. tostring(err) .. "\n")
      end
    end
  end)

  it("should remove a single file synchronously", function()
    local file_path = Path.join(temp_dir, "test_file.txt")
    FS.writefile(file_path, "test")
    assert.is_true(file_exists(file_path), "File should exist before removal")

    local success, err = FS.rm(file_path)
    assert.is_true(success, "Failed to remove file: " .. tostring(err))

    assert.is_false(file_exists(file_path), "File should be removed")
  end)

  it("should remove an empty directory synchronously", function()
    local dir_path = Path.join(temp_dir, "empty_dir")
    local success, err = FS.mkdir(dir_path)
    assert.is_true(success, "Failed to create directory: " .. tostring(err))
    assert.is_true(directory_exists(dir_path), "Directory should exist before removal")

    local rm_success, rm_err = FS.rm(dir_path)
    assert.is_true(rm_success, "Failed to remove directory: " .. tostring(rm_err))
    assert.is_false(directory_exists(dir_path), "Directory should be removed")
  end)

  it("should fail to remove a non-existent path synchronously", function()
    local fake_path = Path.join(temp_dir, "non_existent")
    local success, err = FS.rm(fake_path)
    assert.is_false(success, "Removal should fail for non-existent path")
    assert.is_not_nil(err, "Error message should be provided")
  end)

  it("should fail to remove a non-empty directory without recursive option synchronously", function()
    local dir_path = Path.join(temp_dir, "non_empty_dir")
    local success, err = FS.mkdir(dir_path)
    assert.is_true(success, "Failed to create directory: " .. tostring(err))

    local file_path = Path.join(dir_path, "inner_file.txt")
    FS.writefile(file_path, "test")
    assert.is_true(file_exists(file_path), "Inner file should exist")

    local rm_success, rm_err = FS.rm(dir_path)
    assert.is_false(rm_success, "Removal should fail for non-empty directory without recursive option")
    assert.is_not_nil(rm_err, "Error message should be provided")
    assert.is_true(directory_exists(dir_path), "Directory should still exist")
  end)

  it("should remove a non-empty directory with recursive option synchronously", function()
    local dir_path = Path.join(temp_dir, "recursive_dir")
    local success, err = FS.mkdir(dir_path)
    assert.is_true(success, "Failed to create directory: " .. tostring(err))

    local sub_dir = Path.join(dir_path, "sub_dir")
    success, err = FS.mkdir(sub_dir)
    assert.is_true(success, "Failed to create sub-directory: " .. tostring(err))

    local file_path = Path.join(sub_dir, "inner_file.txt")
    FS.writefile(file_path, "test")
    assert.is_true(file_exists(file_path), "Inner file should exist")

    local rm_success, rm_err = FS.rm(dir_path, { recursive = true })
    assert.is_true(rm_success, "Failed to remove directory recursively: " .. tostring(rm_err))
    assert.is_false(directory_exists(dir_path), "Directory should be removed")
  end)

  it("should handle mixed files and directories recursively", function()
    local dir_path = Path.join(temp_dir, "mixed_dir")
    local success, err = FS.mkdir(dir_path)
    assert.is_true(success, "Failed to create directory: " .. tostring(err))

    local sub_dir1 = Path.join(dir_path, "sub_dir1")
    success, err = FS.mkdir(sub_dir1)
    assert.is_true(success, "Failed to create sub-directory1: " .. tostring(err))

    local sub_dir2 = Path.join(dir_path, "sub_dir2")
    success, err = FS.mkdir(sub_dir2)
    assert.is_true(success, "Failed to create sub-directory2: " .. tostring(err))

    local file1 = Path.join(dir_path, "file1.txt")
    FS.writefile(file1, "test")
    local file2 = Path.join(sub_dir1, "file2.txt")
    FS.writefile(file2, "test")
    local file3 = Path.join(sub_dir2, "file3.txt")
    FS.writefile(file3, "test")

    assert.is_true(file_exists(file1), "file1 should exist")
    assert.is_true(file_exists(file2), "file2 should exist")
    assert.is_true(file_exists(file3), "file3 should exist")

    local rm_success, rm_err = FS.rm(dir_path, { recursive = true })
    assert.is_true(rm_success, "Failed to remove mixed directory recursively: " .. tostring(rm_err))
    assert.is_false(directory_exists(dir_path), "Mixed directory should be removed")
    assert.is_false(file_exists(file1), "file1 should be removed")
    assert.is_false(file_exists(file2), "file2 should be removed")
    assert.is_false(file_exists(file3), "file3 should be removed")
  end)

  -- NOTE: Async one needs some adjustments
  it("should not remove directories with similar prefixes synchronously", function()
    local dir1 = Path.join(temp_dir, "dir")
    local dir2 = Path.join(temp_dir, "directory")
    local success, err = FS.mkdir(dir1)
    assert.is_true(success, "Failed to create dir1: " .. tostring(err))
    success, err = FS.mkdir(dir2)
    assert.is_true(success, "Failed to create dir2: " .. tostring(err))

    local sub_dir = Path.join(dir1, "directory")
    local success, err = FS.mkdir(sub_dir)
    assert.is_true(success, "Failed to create sub_dir: " .. tostring(err))
    local sub_dir2 = Path.join(dir2, "directory")
    local success, err = FS.mkdir(sub_dir2)
    assert.is_true(success, "Failed to create sub_dir: " .. tostring(err))

    local file1 = Path.join(dir1, "file1.txt")
    FS.writefile(file1, "test")
    local file2 = Path.join(dir1, "file2.txt")
    FS.writefile(file2, "test")
    local file3 = Path.join(sub_dir, "file3.txt")
    FS.writefile(file3, "test")
    local file4 = Path.join(dir2, "file4.txt")
    FS.writefile(file4, "test")
    local file5 = Path.join(sub_dir2, "file5.txt")
    FS.writefile(file5, "test")

    local rm_success, rm_err = FS.rm(dir1, { recursive = true })
    assert.is_true(rm_success, "Failed to remove dir1 recursively: " .. tostring(rm_err))
    assert.is_false(directory_exists(dir1), "dir1 should be removed")
    assert.is_false(directory_exists(sub_dir), "sub_dir should be removed")
    assert.is_false(file_exists(file1), "file1 should be removed")
    assert.is_false(file_exists(file2), "file2 should be removed")
    assert.is_false(file_exists(file3), "file3 should be removed")
    assert.is_true(directory_exists(dir2), "dir2 should still exist")
    assert.is_true(directory_exists(sub_dir2), "dir2 should still exist")
    assert.is_true(file_exists(file4), "file4 should be removed")
    assert.is_true(file_exists(file5), "file5 should be removed")
  end)

  it("should handle removal of deeply nested directories synchronously", function()
    local nested_dir = Path.join(temp_dir, "a/b/c/d/e/f")
    local success, err = FS.mkdir(nested_dir, { recursive = true })
    assert.is_true(success, "Failed to create nested directories: " .. tostring(err))

    local file_path = Path.join(nested_dir, "deep_file.txt")
    FS.writefile(file_path, "test")
    assert.is_true(file_exists(file_path), "Deep file should exist")

    local rm_success, rm_err = FS.rm(Path.join(temp_dir, "a"), { recursive = true })
    assert.is_true(rm_success, "Failed to remove deeply nested directories: " .. tostring(rm_err))
    assert.is_false(directory_exists(Path.join(temp_dir, "a")), "Top-level directory 'a' should be removed")
    assert.is_false(directory_exists(Path.join(temp_dir, "a/b/c")), "Top-level directory 'a' should be removed")
    assert.is_false(file_exists(file_path), "Deep file should be removed")
  end)
end)

describe("FS.rm (async)", function()
  local temp_dir

  before_each(function()
    temp_dir = create_temp_dir()
  end)

  after_each(function()
    -- Cleanup: Remove temp_dir if it still exists
    if directory_exists(temp_dir) then
      FS.rm(temp_dir, { recursive = true })
      --   if not success then
      --     io.stderr:write("Failed to clean up temp_dir asynchronously: " .. tostring(err) .. "\n")
      --   end
      -- end)
    end
  end)

  async_it("should remove a single file asynchronously", function(done)
    local file_path = Path.join(temp_dir, "test_file_async.txt")
    FS.writefile(file_path, "test")
    assert.is_true(file_exists(file_path), "File should exist before removal")

    FS.rm(file_path, function(err, success)
      assert.is_nil(err, "Error should be nil")
      assert.is_true(success, "Removal should be successful")
      assert.is_false(file_exists(file_path), "File should be removed")
      done()
    end)
  end)

  async_it("should remove an empty directory asynchronously", function(done)
    local dir_path = Path.join(temp_dir, "empty_dir_async")
    local success, err = FS.mkdir(dir_path)
    assert.is_true(success, "Failed to create directory: " .. tostring(err))
    assert.is_true(directory_exists(dir_path), "Directory should exist before removal")

    FS.rm(dir_path, function(err_rm, success_rm)
      assert.is_nil(err_rm, "Error should be nil")
      assert.is_true(success_rm, "Removal should be successful")
      assert.is_false(directory_exists(dir_path), "Directory should be removed")
      done()
    end)
  end)

  async_it("should FAIL to remove a non-existent path asynchronously", function(done)
    local fake_path = Path.join(temp_dir, "non_existent_async")
    FS.rm(fake_path, function(err, success)
      assert.is_not_nil(err, "Error message should be provided")
      assert.is_equal(err, "Path does not exist: " .. fake_path)
      assert.is_false(success, "Removal should fail for non-existent path")
      done()
    end)
  end)

  async_it("should FAIL to remove a non-empty directory without recursive option asynchronously", function(done)
    local dir_path = Path.join(temp_dir, "non_empty_dir_async")
    local success, err = FS.mkdir(dir_path)
    assert.is_true(success, "Failed to create directory: " .. tostring(err))

    local file_path = Path.join(dir_path, "inner_file_async.txt")
    FS.writefile(file_path, "test")
    assert.is_true(file_exists(file_path), "Inner file should exist")

    FS.rm(dir_path, function(err_rm, success_rm)
      assert.is_not_nil(err_rm, "Error message should be provided")
      assert.is_equal(err_rm, "Failed to remove directory: ENOTEMPTY: directory not empty: " .. dir_path)
      assert.is_false(success_rm, "Removal should fail for non-empty directory without recursive option")
      assert.is_true(directory_exists(dir_path), "Directory should still exist")
      done()
    end)
  end)

  async_it("should remove a non-empty directory with recursive option", function(done)
    local dir_path = Path.join(temp_dir, "recursive_dir_async")
    local success, err = FS.mkdir(dir_path)
    assert.is_true(success, "Failed to create directory: " .. tostring(err))

    local sub_dir = Path.join(dir_path, "sub_dir_async")
    success, err = FS.mkdir(sub_dir)
    assert.is_true(success, "Failed to create sub-directory: " .. tostring(err))

    local file_path = Path.join(sub_dir, "inner_file_async.txt")
    FS.writefile(file_path, "test")
    assert.is_true(file_exists(file_path), "Inner file should exist")

    FS.rm(dir_path, { recursive = true }, function(err_rm, success_rm)
      assert.is_nil(err_rm, "Error should be nil")
      assert.is_true(success_rm, "Removal should be successful")
      assert.is_false(directory_exists(dir_path), "Directory should be removed")
      done()
    end)
  end)

  async_it("should handle mixed files and directories recursively", function(done)
    local dir_path = Path.join(temp_dir, "mixed_dir")
    local success, err = FS.mkdir(dir_path)
    assert.is_true(success, "Failed to create directory: " .. tostring(err))

    local sub_dir1 = Path.join(dir_path, "sub_dir1")
    success, err = FS.mkdir(sub_dir1)
    assert.is_true(success, "Failed to create sub-directory1: " .. tostring(err))

    local sub_dir2 = Path.join(dir_path, "sub_dir2")
    success, err = FS.mkdir(sub_dir2)
    assert.is_true(success, "Failed to create sub-directory2: " .. tostring(err))

    local file1 = Path.join(dir_path, "file1.txt")
    FS.writefile(file1, "test")
    local file2 = Path.join(sub_dir1, "file2.txt")
    FS.writefile(file2, "test")
    local file3 = Path.join(sub_dir2, "file3.txt")
    FS.writefile(file3, "test")

    assert.is_true(file_exists(file1), "file1 should exist")
    assert.is_true(file_exists(file2), "file2 should exist")
    assert.is_true(file_exists(file3), "file3 should exist")

    FS.rm(dir_path, { recursive = true }, function(rm_err, rm_success)
      assert.is_true(rm_success, "Failed to remove mixed directory recursively: " .. tostring(rm_err))
      assert.is_false(directory_exists(dir_path), "Mixed directory should be removed")
      assert.is_false(file_exists(file1), "file1 should be removed")
      assert.is_false(file_exists(file2), "file2 should be removed")
      assert.is_false(file_exists(file3), "file3 should be removed")
      done()
    end)
  end)

  async_it("should not remove directories with similar prefixes synchronously", function(done)
    local dir1 = Path.join(temp_dir, "dir")
    local dir2 = Path.join(temp_dir, "directory")
    local success, err = FS.mkdir(dir1)
    assert.is_true(success, "Failed to create dir1: " .. tostring(err))
    success, err = FS.mkdir(dir2)
    assert.is_true(success, "Failed to create dir2: " .. tostring(err))

    local sub_dir = Path.join(dir1, "directory")
    local success, err = FS.mkdir(sub_dir)
    assert.is_true(success, "Failed to create sub_dir: " .. tostring(err))
    local sub_dir2 = Path.join(dir2, "directory")
    local success, err = FS.mkdir(sub_dir2)
    assert.is_true(success, "Failed to create sub_dir: " .. tostring(err))

    local file1 = Path.join(dir1, "file1.txt")
    FS.writefile(file1, "test")
    local file2 = Path.join(dir1, "file2.txt")
    FS.writefile(file2, "test")
    local file3 = Path.join(sub_dir, "file3.txt")
    FS.writefile(file3, "test")
    local file4 = Path.join(dir2, "file4.txt")
    FS.writefile(file4, "test")
    local file5 = Path.join(sub_dir2, "file5.txt")
    FS.writefile(file5, "test")

    FS.rm(dir1, { recursive = true }, function(rm_err, rm_success)
      assert.is_true(rm_success, "Failed to remove dir1 recursively: " .. tostring(rm_err))
      assert.is_false(directory_exists(dir1), "dir1 should be removed")
      assert.is_false(directory_exists(sub_dir), "sub_dir should be removed")
      assert.is_false(file_exists(file1), "file1 should be removed")
      assert.is_false(file_exists(file2), "file2 should be removed")
      assert.is_false(file_exists(file3), "file3 should be removed")
      assert.is_true(directory_exists(dir2), "dir2 should still exist")
      assert.is_true(directory_exists(sub_dir2), "dir2 should still exist")
      assert.is_true(file_exists(file4), "file4 should be removed")
      assert.is_true(file_exists(file5), "file5 should be removed")
      done()
    end)
  end)

  async_it("should handle removal of deeply nested directories synchronously", function(done)
    local nested_dir = Path.join(temp_dir, "a/b/c/d/e/f")
    local success, err = FS.mkdir(nested_dir, { recursive = true })
    assert.is_true(success, "Failed to create nested directories: " .. tostring(err))

    local file_path = Path.join(nested_dir, "deep_file.txt")
    FS.writefile(file_path, "test")
    assert.is_true(file_exists(file_path), "Deep file should exist")

    FS.rm(Path.join(temp_dir, "a"), { recursive = true }, function(rm_err, rm_success)
      assert.is_true(rm_success, "Failed to remove deeply nested directories: " .. tostring(rm_err))
      assert.is_false(directory_exists(Path.join(temp_dir, "a")), "Top-level directory 'a' should be removed")
      assert.is_false(directory_exists(Path.join(temp_dir, "a/b/c")), "Top-level directory 'a' should be removed")
      assert.is_false(file_exists(file_path), "Deep file should be removed")
      done()
    end)
  end)
end)
