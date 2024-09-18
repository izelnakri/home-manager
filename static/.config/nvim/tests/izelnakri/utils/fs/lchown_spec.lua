require("async.test")

local FS = require("izelnakri.utils.fs")
local uv = vim.loop

describe("FS.lchown (async)", function()
  local tmp_dir = "tmp"
  local test_path
  local test_uid = uv.getuid() -- Use the current user's UID
  local test_gid = uv.getgid() -- Use the current user's GID
  local valid_fd

  before_each(function()
    -- Create a relative temporary directory for the test
    local _, err = uv.fs_mkdir(tmp_dir, 493) -- 493 is 0755 in octal
    if err and err ~= "EEXIST" then
      error("Failed to create temporary directory: " .. tostring(err))
    end

    -- Define the test file path within the temporary directory
    test_path = tmp_dir .. "/testfile_lchown"

    -- Create the test file
    valid_fd, err = uv.fs_open(test_path, "w", 438) -- 438 is 0666 in octal
    assert(valid_fd, "Failed to create test file: " .. tostring(err))
    uv.fs_close(valid_fd)

    -- Re-open the file descriptor for the test
    valid_fd, err = uv.fs_open(test_path, "r", 438)
    assert(valid_fd, "Failed to open test file: " .. tostring(err))
  end)

  after_each(function()
    -- Ensure the file descriptor is closed
    if valid_fd then
      uv.fs_close(valid_fd)
    end

    -- Clean up the test file and directory
    if test_path then
      uv.fs_unlink(test_path)
    end

    if tmp_dir then
      uv.fs_rmdir(tmp_dir)
    end
  end)

  it("should change ownership synchronously by path", function()
    local stat, stat_err = uv.fs_stat(test_path)
    assert(not stat_err, "File does not exist or cannot be accessed: " .. tostring(stat_err))
    assert(stat, "Failed to stat test file before lchown")

    local result, err = FS.lchown(test_path, test_uid, test_gid)
    assert(not err, "Expected no error, got: " .. tostring(err))
    assert(result, "Expected true, got: " .. tostring(result))

    stat, stat_err = uv.fs_stat(test_path)
    assert(not stat_err, "Failed to stat test file after lchown")
    assert(stat, "Stat failed after lchown")
    assert.equals(test_uid, stat.uid, "UID did not change as expected")
    assert.equals(test_gid, stat.gid, "GID did not change as expected")
  end)

  it("should change ownership synchronously by path", function()
    local result, err = FS.lchown(test_path, test_uid, test_gid)
    assert.is_true(result)
    assert.is_nil(err)
  end)

  it("should change ownership synchronously by file descriptor", function()
    local result, err = FS.lchown(valid_fd, test_uid, test_gid)
    assert.is_true(result)
    assert.is_nil(err)
  end)

  it("should return an error for an invalid file descriptor", function()
    assert.has.errors(function()
      FS.lchown(invalid_fd, test_uid, test_gid)
    end)
  end)

  it("should return an error for a non-existent path", function()
    assert.has.errors(function()
      FS.lchown("/non/existent/path", test_uid, test_gid)
    end)
  end)

  it("should allow custom file open options", function()
    local result, err = FS.lchown(test_path, test_uid, test_gid, nil, { flag = "r", mode = 420 })
    assert.is_true(result)
    assert.is_nil(err)
  end)
end)

describe("FS.lchown (sync)", function()
  local tmp_dir = "tmp"
  local test_path
  local test_uid = uv.getuid() -- Use the current user's UID
  local test_gid = uv.getgid() -- Use the current user's GID
  local valid_fd

  before_each(function()
    -- Create a relative temporary directory for the test
    local _, err = uv.fs_mkdir(tmp_dir, 493) -- 493 is 0755 in octal
    if err and err ~= "EEXIST" then
      error("Failed to create temporary directory: " .. tostring(err))
    end

    -- Define the test file path within the temporary directory
    test_path = tmp_dir .. "/testfile_lchown"

    -- Create the test file
    valid_fd, err = uv.fs_open(test_path, "w", 438) -- 438 is 0666 in octal
    assert(valid_fd, "Failed to create test file: " .. tostring(err))
    uv.fs_close(valid_fd)

    -- Re-open the file descriptor for the test
    valid_fd, err = uv.fs_open(test_path, "r", 438)
    assert(valid_fd, "Failed to open test file: " .. tostring(err))
  end)

  after_each(function()
    -- Ensure the file descriptor is closed
    if valid_fd then
      uv.fs_close(valid_fd)
    end

    -- Clean up the test file and directory
    if test_path then
      uv.fs_unlink(test_path)
    end

    if tmp_dir then
      uv.fs_rmdir(tmp_dir)
    end
  end)

  it("should change ownership synchronously by path", function()
    local stat, stat_err = uv.fs_stat(test_path)
    assert(not stat_err, "File does not exist or cannot be accessed: " .. tostring(stat_err))
    assert(stat, "Failed to stat test file before lchown")

    local result, err = FS.lchown(test_path, test_uid, test_gid)
    assert(not err, "Expected no error, got: " .. tostring(err))
    assert(result, "Expected true, got: " .. tostring(result))

    stat, stat_err = uv.fs_stat(test_path)
    assert(not stat_err, "Failed to stat test file after lchown")
    assert(stat, "Stat failed after lchown")
    assert.equals(test_uid, stat.uid, "UID did not change as expected")
    assert.equals(test_gid, stat.gid, "GID did not change as expected")
  end)

  it("should change ownership synchronously by path", function()
    local result, err = FS.lchown(test_path, test_uid, test_gid)
    assert.is_true(result)
    assert.is_nil(err)
  end)

  it("should change ownership synchronously by file descriptor", function()
    local result, err = FS.lchown(valid_fd, test_uid, test_gid)
    assert.is_true(result)
    assert.is_nil(err)
  end)

  it("should return an error for an invalid file descriptor", function()
    assert.has.errors(function()
      FS.lchown(invalid_fd, test_uid, test_gid)
    end)
  end)

  it("should return an error for a non-existent path", function()
    assert.has.errors(function()
      FS.lchown("/non/existent/path", test_uid, test_gid)
    end)
  end)

  it("should allow custom file open options", function()
    local result, err = FS.lchown(test_path, test_uid, test_gid, nil, { flag = "r", mode = 420 })
    assert.is_true(result)
    assert.is_nil(err)
  end)
end)
