require("async.test")

local uv = vim.uv
local FS = require("izelnakri.utils.fs")
local List = require("izelnakri.utils.list")
local Path = require("izelnakri.utils.path")

local TMP_FOLDER_PATH = "tests/izelnakri/tmp/"

describe("FS.mkdir (sync)", function()
  before_each(function()
    -- Ensure the temporary directory exists
    local stat = uv.fs_stat(TMP_FOLDER_PATH)
    if not stat then
      local ok, err = pcall(function()
        uv.fs_mkdir(TMP_FOLDER_PATH, 493) -- 0755 in decimal
      end)
      if not ok then
        error("Failed to create temporary directory: " .. tostring(err))
      end
    end
  end)

  after_each(function()
    -- Clean up all test files and directories after each test
    local function cleanup_dir(dir)
      local entries = uv.fs_scandir(dir)
      if not entries then
        return
      end
      while true do
        local name, type = uv.fs_scandir_next(entries)
        if not name then
          break
        end
        local full_path = Path.join({ dir, name })
        if type == "directory" then
          cleanup_dir(full_path)
        end
        uv.fs_unlink(full_path)
      end
      uv.fs_rmdir(dir)
    end

    local files = {
      "testdir",
      "existingdir",
      "existingdir2",
      "recursivedir/subdir1/subdir2",
      "recursivedir",
      "file_in_path.txt",
      "readonlydir",
      "invalidpath\0",
    }

    for _, relative_path in ipairs(files) do
      local full_path = Path.join({ TMP_FOLDER_PATH, relative_path })
      local stat = uv.fs_stat(full_path)
      if stat then
        if stat.type == "directory" then
          -- If directory is readonly, change permissions to allow deletion
          if stat.mode then
            uv.fs_chmod(full_path, 493) -- 0755
          end
          cleanup_dir(full_path)
        else
          uv.fs_unlink(full_path)
        end
      end
    end
  end)

  it("should create a single directory successfully", function()
    local dir_path = Path.join({ TMP_FOLDER_PATH, "testdir" })
    local result = FS.mkdir(dir_path)

    assert.is_true(result, "FS.mkdir should succeed without errors")

    local stat = uv.fs_stat(dir_path)
    assert.is_not_nil(stat, "Directory should exist after creation")
    assert.is_equal(stat.type, "directory", "Path should be a directory")
  end)

  it("should throw an error when creating an existing directory", function()
    local dir_path = Path.join({ TMP_FOLDER_PATH, "existingdir" })
    FS.mkdir(dir_path)

    assert.has_error(function()
      FS.mkdir(dir_path)
    end, "EEXIST: folder already exists: " .. dir_path)
  end)

  it("should not throw an error when creating an existing directory recursively", function()
    local dir_path = Path.join({ TMP_FOLDER_PATH, "existingdir2" })

    FS.mkdir(dir_path)
    FS.mkdir(dir_path, { recursive = true })
    local stat = uv.fs_stat(dir_path)
    assert.is_not_nil(stat, "Directory should exist after creation")
    assert.is_equal(stat.type, "directory", "Path should be a directory")
  end)

  it("should create directories recursively successfully", function()
    local dir_path = Path.join({ TMP_FOLDER_PATH, "recursivedir", "subdir1", "subdir2" })
    local result = FS.mkdir(dir_path, { recursive = true })

    assert.is_true(result, "FS.mkdir with recursive=true should succeed without errors")

    local stat = uv.fs_stat(dir_path)
    assert.is_not_nil(stat, "Nested directories should exist after recursive creation")
    assert.is_equal(stat.type, "directory", "Path should be a directory")
  end)

  it("should throw an error when a file exists in the path", function()
    local file_path = Path.join({ TMP_FOLDER_PATH, "file_in_path.txt" })
    FS.writefile(file_path, "This is a test file.")

    local dir_path = Path.join({ TMP_FOLDER_PATH, "file_in_path.txt", "subdir" })
    assert.has_error(function()
      FS.mkdir(dir_path, { recursive = true })
    end, "EEXIST: file already exists: " .. Path.join({ TMP_FOLDER_PATH, "file_in_path.txt" }))
  end)

  it("should throw an error due to permission issues", function()
    local dir_path = Path.join({ TMP_FOLDER_PATH, "readonlydir" })
    FS.mkdir(dir_path)

    local chmod_ok, chmod_err = pcall(function()
      uv.fs_chmod(dir_path, 0) -- No permissions
    end)
    assert.is_true(chmod_ok, "Changing directory permissions should succeed")

    local subdir_path = Path.join({ dir_path, "subdir" })
    assert.has_error(function()
      FS.mkdir(subdir_path)
    end)

    -- Restore permissions for cleanup
    uv.fs_chmod(dir_path, 493) -- 0755
  end)

  it("should throw an error when provided with an invalid path", function()
    local invalid_path = TMP_FOLDER_PATH .. "invalid\0path" -- Null byte is invalid in paths
    assert.has_error(function()
      FS.mkdir(invalid_path)
    end)
  end)
end)

describe("FS.mkdir (async)", function()
  before_each(function()
    -- Ensure the temporary directory exists
    local stat = uv.fs_stat(TMP_FOLDER_PATH)
    if not stat then
      local ok, err = pcall(function()
        uv.fs_mkdir(TMP_FOLDER_PATH, 493) -- 0755 in decimal
      end)
      if not ok then
        error("Failed to create temporary directory: " .. tostring(err))
      end
    end
  end)

  after_each(function()
    -- Clean up all test files and directories after each test
    local function cleanup_dir(dir)
      local entries = uv.fs_scandir(dir)
      if not entries then
        return
      end
      while true do
        local name, type = uv.fs_scandir_next(entries)
        if not name then
          break
        end
        local full_path = Path.join({ dir, name })
        if type == "directory" then
          cleanup_dir(full_path)
        end
        uv.fs_unlink(full_path)
      end
      uv.fs_rmdir(dir)
    end

    local files = {
      "async-testdir",
      "async-existingdir",
      "async-existingdir2",
      "async-recursivedir/subdir1/subdir2",
      "async-recursivedir",
      "async-file_in_path.txt",
      "async-readonlydir",
      "async-invalidpath\0",
    }

    for _, relative_path in ipairs(files) do
      local full_path = Path.join({ TMP_FOLDER_PATH, relative_path })
      local stat = uv.fs_stat(full_path)
      if stat then
        if stat.type == "directory" then
          -- If directory is readonly, change permissions to allow deletion
          if stat.mode then
            uv.fs_chmod(full_path, 493) -- 0755
          end
          cleanup_dir(full_path)
        else
          uv.fs_unlink(full_path)
        end
      end
    end
  end)

  async_it("should create a single directory successfully", function()
    local dir_path = Path.join({ TMP_FOLDER_PATH, "async-testdir" })
    FS.mkdir(dir_path, function(err, result)
      assert.is_true(result, "FS.mkdir should succeed without errors")

      local stat = uv.fs_stat(dir_path)
      assert.is_not_nil(stat, "Directory should exist after creation")
      assert.is_equal(stat.type, "directory", "Path should be a directory")

      done()
    end)
  end)

  async_it("should throw an error when creating an existing directory", function()
    local dir_path = Path.join({ TMP_FOLDER_PATH, "async-existingdir" })

    FS.mkdir(dir_path)

    FS.mkdir(dir_path, function(err, result)
      assert.is_equal(result, false)
      assert.is_equal(err, "EEXIST: folder already exists: " .. dir_path)
      done()
    end)
  end)

  async_it("should not throw an error when creating an existing directory recursively", function()
    local dir_path = Path.join({ TMP_FOLDER_PATH, "existingdir2" })

    FS.mkdir(dir_path)
    FS.mkdir(dir_path, { recursive = true }, function(err, result)
      assert.is_nil(err)

      -- assert.is_equal(result, true) -- TODO: this should be false

      local stat = uv.fs_stat(dir_path)
      assert.is_not_nil(stat, "Directory should exist after creation")
      assert.is_equal(stat.type, "directory", "Path should be a directory")

      done()
    end)
  end)

  async_it("should create directories recursively successfully", function()
    local dir_path = Path.join({ TMP_FOLDER_PATH, "async-recursivedir", "subdir1", "subdir2" })

    FS.mkdir(dir_path, { recursive = true }, function(_err, result)
      assert.is_true(result, "FS.mkdir with recursive=true should succeed without errors")

      local stat = uv.fs_stat(dir_path)
      assert.is_not_nil(stat, "Nested directories should exist after recursive creation")
      assert.is_equal(stat.type, "directory", "Path should be a directory")
      done()
    end)
  end)

  async_it("should throw an error when a file exists in the path", function()
    local file_path = Path.join({ TMP_FOLDER_PATH, "async-file_in_path.txt" })
    FS.writefile(file_path, "This is a test file.")

    local dir_path = Path.join({ TMP_FOLDER_PATH, "async-file_in_path.txt", "subdir" })

    FS.mkdir(dir_path, { recursive = true }, function(err)
      assert.is_equal(err, "EEXIST: file already exists: " .. Path.join({ TMP_FOLDER_PATH, "async-file_in_path.txt" }))
      done()
    end)
  end)

  async_it("should throw an error due to permission issues", function()
    local dir_path = Path.join({ TMP_FOLDER_PATH, "async-readonlydir" })
    FS.mkdir(dir_path)

    local chmod_ok, chmod_err = pcall(function()
      uv.fs_chmod(dir_path, 0) -- No permissions
    end)
    assert.is_true(chmod_ok, "Changing directory permissions should succeed")

    local subdir_path = Path.join({ dir_path, "subdir" })
    FS.mkdir(subdir_path, function(err, result)
      assert.is_not_nil(err)
      assert.is_not_true(result)

      -- Restore permissions for cleanup
      uv.fs_chmod(dir_path, 493) -- 0755
      done()
    end)
  end)

  async_it("should throw an error when provided with an invalid path", function()
    local invalid_path = TMP_FOLDER_PATH .. "async-invalid\0path" -- Null byte is invalid in paths
    FS.mkdir(invalid_path, function(err, result)
      assert.is_not_nil(err)
      assert.is_not_true(result)
      done()
    end)
  end)
end)
