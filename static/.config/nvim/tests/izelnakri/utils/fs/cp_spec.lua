require("async.test")

local Path = require("izelnakri.utils.path")
local cp = require("izelnakri.utils.fs.cp")
local uv = vim.uv

local function create_temp_dir()
  local tmp_dir = Path.join(os.tmpname())
  -- os.tmpname() may create a file; ensure it's a directory
  os.remove(tmp_dir)
  local success, err = uv.fs_mkdir(tmp_dir, 493) -- 0755 permissions
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

local function writefile(file_path, content)
  local fd, err = uv.fs_open(file_path, "w", 438) -- 0666 permissions
  assert.is_not_nil(fd, "Failed to open file for writing: " .. tostring(err))
  uv.fs_write(fd, content, -1)
  uv.fs_close(fd)
end

local function readfile(file_path)
  local fd, err = uv.fs_open(file_path, "r", 438)
  assert.is_not_nil(fd, "Failed to open file for reading: " .. tostring(err))
  local data, err = uv.fs_read(fd, 4096, 0)
  uv.fs_close(fd)
  return data
end

describe("FS.cp (sync)", function()
  local temp_dir
  local cp_dir

  before_each(function()
    temp_dir = create_temp_dir()
    cp_dir = Path.join(temp_dir, "cp_test")
    local success, err = uv.fs_mkdir(cp_dir, 493) -- 0755
    assert.is_true(success, "Failed to create cp_test directory: " .. tostring(err))
  end)

  after_each(function()
    -- Cleanup: Remove cp_dir if it still exists
    if directory_exists(cp_dir) then
      -- Implement FS.rm or use existing FS.rm if available
      local rm = require("izelnakri.utils.fs.rm")
      local success, err = rm(cp_dir, { recursive = true })
      if not success then
        io.stderr:write("Failed to clean up cp_dir: " .. tostring(err) .. "\n")
      end
    end
  end)

  it("should copy a single file synchronously", function()
    local src_file = Path.join(temp_dir, "source_file.txt")
    local dest_file = Path.join(cp_dir, "dest_file.txt")
    writefile(src_file, "Hello, World!")

    local success, err = cp(src_file, dest_file)
    assert.is_true(success, "Failed to copy file: " .. tostring(err))
    assert.is_nil(err)

    assert.is_true(file_exists(dest_file), "Destination file should exist")
    assert.are.equal(readfile(dest_file), "Hello, World!", "File content should match")
  end)

  it("should overwrite an existing file synchronously when force option is true", function()
    local src_file = Path.join(temp_dir, "source_file.txt")
    local dest_file = Path.join(cp_dir, "dest_file.txt")
    writefile(src_file, "Hello, World!")
    writefile(dest_file, "Old Content")

    local success, err = cp(src_file, dest_file)
    assert.is_true(success, "Failed to overwrite file: " .. tostring(err))
    assert.is_nil(err)

    assert.are.equal(readfile(dest_file), "Hello, World!", "Destination file should be overwritten")
  end)

  it("should fail to overwrite an existing file synchronously when force option is false", function()
    local src_file = Path.join(temp_dir, "source_file.txt")
    local dest_file = Path.join(cp_dir, "dest_file.txt")
    writefile(src_file, "Hello, World!")
    writefile(dest_file, "Old Content")

    local success, err = cp(src_file, dest_file, { force = false })
    assert.is_false(success, "Overwrite should fail when force option is false")
    assert.is_not_nil(err, "Error message should be provided")

    assert.are.equal(readfile(dest_file), "Old Content", "Destination file should not be overwritten")
  end)

  it("should fail to overwrite an existing file synchronously when error_on_exist is true", function()
    local src_file = Path.join(temp_dir, "source_file.txt")
    local dest_file = Path.join(cp_dir, "dest_file.txt")
    writefile(src_file, "Hello, World!")
    writefile(dest_file, "Existing Content")

    local success, err = cp(src_file, dest_file, { error_on_exist = true })
    assert.is_false(success, "Overwrite should fail when error_on_exist is true")
    assert.is_not_nil(err, "Error message should be provided")

    assert.are.equal(readfile(dest_file), "Existing Content", "Destination file should not be overwritten")
  end)

  it("should copy a directory recursively synchronously", function()
    local src_dir = Path.join(temp_dir, "src_dir")
    local dest_dir = Path.join(cp_dir, "dest_dir")
    assert.is_true(uv.fs_mkdir(src_dir, 493), "Failed to create src_dir")

    -- Create nested directories and files
    local nested_dir = Path.join(src_dir, "nested")
    assert.is_true(uv.fs_mkdir(nested_dir, 493), "Failed to create nested directory")

    local file1 = Path.join(src_dir, "file1.txt")
    local file2 = Path.join(nested_dir, "file2.txt")
    writefile(file1, "File 1 Content")
    writefile(file2, "File 2 Content")

    local success, err = cp(src_dir, dest_dir, { recursive = true })
    assert.is_true(success, "Failed to copy directory: " .. tostring(err))

    assert.is_true(directory_exists(dest_dir), "Destination directory should exist")
    assert.is_true(file_exists(Path.join(dest_dir, "file1.txt")), "file1.txt should be copied")
    assert.is_true(file_exists(Path.join(dest_dir, "nested", "file2.txt")), "file2.txt should be copied")

    assert.are.equal(readfile(Path.join(dest_dir, "file1.txt")), "File 1 Content", "file1.txt content should match")
    assert.are.equal(
      readfile(Path.join(dest_dir, "nested", "file2.txt")),
      "File 2 Content",
      "file2.txt content should match"
    )
  end)

  it("should fail to copy a directory recursively without the recursive option", function()
    local src_dir = Path.join(temp_dir, "src_dir_non_recursive")
    local dest_dir = Path.join(cp_dir, "dest_dir_non_recursive")
    assert.is_true(uv.fs_mkdir(src_dir, 493), "Failed to create src_dir_non_recursive")

    local file1 = Path.join(src_dir, "file1.txt")
    writefile(file1, "File 1 Content")

    local success, err = cp(src_dir, dest_dir)
    assert.is_false(success, "Copying directory without recursive option should fail")
    assert.are.equal(err, "Cannot copy directory without recursive option")

    assert.is_false(directory_exists(dest_dir), "Destination directory should not exist")
  end)

  it("should copy the target of a symlink when dereference is true synchronously", function()
    local src_target = Path.join(temp_dir, "target.txt")
    writefile(src_target, "Target Content")
    local src_symlink = Path.join(temp_dir, "symlink")
    uv.fs_symlink(src_target, src_symlink)

    local dest_file = Path.join(cp_dir, "symlink_copy.txt")

    local success, err = cp(src_symlink, dest_file)
    assert.is_true(success, "Failed to copy symlink target: " .. tostring(err))

    assert.is_true(file_exists(dest_file), "Destination file should exist")
    assert.are.equal(readfile(dest_file), "Target Content", "File content should match the symlink target")
  end)

  it("should apply filter function synchronously to exclude certain files", function()
    local src_dir = Path.join(temp_dir, "src_dir_filter")
    local sub_dir = Path.join(src_dir, "sub_folder")
    local dest_dir = Path.join(cp_dir, "dest_dir_filter")
    local dest_sub_dir = Path.join(dest_dir, "sub_folder")
    assert.is_true(uv.fs_mkdir(src_dir, 493), "Failed to create src_dir_filter")
    assert.is_true(uv.fs_mkdir(sub_dir, 493), "Failed to create src_dir_filter")

    local file1 = Path.join(src_dir, "file1.txt")
    local file2 = Path.join(src_dir, "file2.log")
    local file3 = Path.join(sub_dir, "file3.log")
    local file4 = Path.join(sub_dir, "file4.txt")
    local file5 = Path.join(sub_dir, "file5.txt")
    writefile(file1, "File 1 Content")
    writefile(file2, "File 2 Content")
    writefile(file3, "File 3 Content")
    writefile(file4, "File 4 Content")
    writefile(file5, "File 5 Content")

    local success, err = cp(src_dir, dest_dir, {
      recursive = true,
      filter = function(type_, path_)
        if type_ == "file" and path_:match("%.log$") then
          return false
        end
        return true
      end,
    })
    assert.is_true(success, "Failed to copy directory with filter: " .. tostring(err))
    assert.is_true(directory_exists(dest_dir), "Destination directory should exist")
    assert.is_true(file_exists(Path.join(dest_dir, "file1.txt")), "file1.txt should be copied")
    assert.is_false(file_exists(Path.join(dest_dir, "file2.log")), "file2.log should be excluded by filter")
    assert.is_true(directory_exists(dest_sub_dir), "Destination sub directory should exist")
    assert.is_false(file_exists(Path.join(dest_sub_dir, "file3.log")), "file3.log should be excluded by filter")
    assert.is_true(file_exists(Path.join(dest_sub_dir, "file4.txt")), "file4.txt should be copied")
    assert.is_true(file_exists(Path.join(dest_sub_dir, "file5.txt")), "file5.txt should be copied")
  end)

  it("should preserve timestamps when preserve_timestamps is true", function()
    local src_file = Path.join(temp_dir, "source_file_timestamp.txt")
    local dest_file = Path.join(cp_dir, "dest_file_timestamp.txt")
    writefile(src_file, "Timestamp Content")

    local current_time = os.time()
    uv.fs_utime(src_file, current_time, current_time)

    local success, err = cp(src_file, dest_file, { preserve_timestamps = true })
    assert.is_true(success, "Failed to copy file with preserved timestamps: " .. tostring(err))

    local stat_src = uv.fs_stat(src_file)
    local stat_dest = uv.fs_stat(dest_file)
    assert.is_not_nil(stat_src, "Source file stat should exist")
    assert.is_not_nil(stat_dest, "Destination file stat should exist")
    assert.are.equal(stat_src.atime.sec, stat_dest.atime.sec, "Access times should match")
    assert.are.equal(stat_src.mtime.sec, stat_dest.mtime.sec, "Modification times should match")
  end)
end)

describe("FS.cp (async)", function()
  local temp_dir
  local cp_dir

  before_each(function()
    temp_dir = create_temp_dir()
    cp_dir = Path.join(temp_dir, "cp_test_async")
    local success, err = uv.fs_mkdir(cp_dir, 493) -- 0755
    assert.is_true(success, "Failed to create cp_test_async directory: " .. tostring(err))
  end)

  after_each(function()
    -- Cleanup: Remove cp_dir if it still exists
    if directory_exists(cp_dir) then
      -- Implement FS.rm or use existing FS.rm if available
      local rm = require("izelnakri.utils.fs.rm")
      local success, err = rm(cp_dir, { recursive = true })
      if not success then
        io.stderr:write("Failed to clean up cp_dir_async: " .. tostring(err) .. "\n")
      end
    end
  end)

  async_it("should copy a single file asynchronously", function(done)
    vim.print(temp_dir)
    local src_file = Path.join(temp_dir, "source_file.txt")
    local dest_file = Path.join(cp_dir, "dest_file.txt")
    writefile(src_file, "Hello, World!")

    cp(src_file, dest_file, function(err, success)
      vim.print("err", err)
      vim.print("succeess:", success)
      assert.is_true(success, "Failed to copy file: " .. tostring(err))
      assert.is_nil(err)

      assert.is_true(file_exists(dest_file), "Destination file should exist")
      assert.are.equal(readfile(dest_file), "Hello, World!", "File content should match")
      done()
    end)
  end)

  async_it("should overwrite an existing file asynchronously when force option is true", function(done)
    local src_file = Path.join(temp_dir, "source_file.txt")
    local dest_file = Path.join(cp_dir, "dest_file.txt")
    writefile(src_file, "Hello, World!")
    writefile(dest_file, "Old Content")

    cp(src_file, dest_file, function(err, success)
      assert.is_true(success, "Failed to overwrite file: " .. tostring(err))
      assert.is_nil(err)

      assert.are.equal(readfile(dest_file), "Hello, World!", "Destination file should be overwritten")
      done()
    end)
  end)

  async_it("should fail to overwrite an existing file asynchronously when force option is false", function(done)
    local src_file = Path.join(temp_dir, "source_file.txt")
    local dest_file = Path.join(cp_dir, "dest_file.txt")
    writefile(src_file, "Hello, World!")
    writefile(dest_file, "Old Content")

    cp(src_file, dest_file, { force = false }, function(err, success)
      assert.is_false(success, "Overwrite should fail when force option is false")
      assert.is_not_nil(err, "Error message should be provided")

      assert.are.equal(readfile(dest_file), "Old Content", "Destination file should not be overwritten")
      done()
    end)
  end)

  async_it("should fail to overwrite an existing file asynchronously when error_on_exist is true", function(done)
    local src_file = Path.join(temp_dir, "source_file.txt")
    local dest_file = Path.join(cp_dir, "dest_file.txt")
    writefile(src_file, "Hello, World!")
    writefile(dest_file, "Existing Content")

    cp(src_file, dest_file, { error_on_exist = true }, function(err, success)
      assert.is_false(success, "Overwrite should fail when error_on_exist is true")
      assert.is_not_nil(err, "Error message should be provided")

      assert.are.equal(readfile(dest_file), "Existing Content", "Destination file should not be overwritten")
      done()
    end)
  end)

  async_it("should copy a directory recursively asynchronously", function(done)
    local src_dir = Path.join(temp_dir, "src_dir")
    local dest_dir = Path.join(cp_dir, "dest_dir")
    assert.is_true(uv.fs_mkdir(src_dir, 493), "Failed to create src_dir")

    -- Create nested directories and files
    local nested_dir = Path.join(src_dir, "nested")
    assert.is_true(uv.fs_mkdir(nested_dir, 493), "Failed to create nested directory")

    local file1 = Path.join(src_dir, "file1.txt")
    local file2 = Path.join(nested_dir, "file2.txt")
    writefile(file1, "File 1 Content")
    writefile(file2, "File 2 Content")

    cp(src_dir, dest_dir, { recursive = true }, function(err, success)
      assert.is_true(success, "Failed to copy directory: " .. tostring(err))

      assert.is_true(directory_exists(dest_dir), "Destination directory should exist")
      assert.is_true(file_exists(Path.join(dest_dir, "file1.txt")), "file1.txt should be copied")
      assert.is_true(file_exists(Path.join(dest_dir, "nested", "file2.txt")), "file2.txt should be copied")

      assert.are.equal(readfile(Path.join(dest_dir, "file1.txt")), "File 1 Content", "file1.txt content should match")
      assert.are.equal(
        readfile(Path.join(dest_dir, "nested", "file2.txt")),
        "File 2 Content",
        "file2.txt content should match"
      )
      done()
    end)
  end)

  async_it("should fail to copy a directory recursively without the recursive option", function(done)
    local src_dir = Path.join(temp_dir, "src_dir_non_recursive")
    local dest_dir = Path.join(cp_dir, "dest_dir_non_recursive")
    assert.is_true(uv.fs_mkdir(src_dir, 493), "Failed to create src_dir_non_recursive")

    local file1 = Path.join(src_dir, "file1.txt")
    writefile(file1, "File 1 Content")

    cp(src_dir, dest_dir, function(err, success)
      assert.is_false(success, "Copying directory without recursive option should fail")
      assert.are.equal(err, "Cannot copy directory without recursive option")

      assert.is_false(directory_exists(dest_dir), "Destination directory should not exist")
      done()
    end)
  end)

  async_it("should copy the target of a symlink when dereference is true asynchronously", function(done)
    local src_target = Path.join(temp_dir, "target.txt")
    writefile(src_target, "Target Content")
    local src_symlink = Path.join(temp_dir, "symlink")
    uv.fs_symlink(src_target, src_symlink)

    local dest_file = Path.join(cp_dir, "symlink_copy.txt")

    cp(src_symlink, dest_file, function(err, success)
      assert.is_true(success, "Failed to copy symlink target: " .. tostring(err))

      assert.is_true(file_exists(dest_file), "Destination file should exist")
      assert.are.equal(readfile(dest_file), "Target Content", "File content should match the symlink target")
      done()
    end)
  end)

  async_it("should apply filter function asynchronously to exclude certain files", function(done)
    local src_dir = Path.join(temp_dir, "src_dir_filter")
    local sub_dir = Path.join(src_dir, "sub_folder")
    local dest_dir = Path.join(cp_dir, "dest_dir_filter")
    local dest_sub_dir = Path.join(dest_dir, "sub_folder")
    assert.is_true(uv.fs_mkdir(src_dir, 493), "Failed to create src_dir_filter")
    assert.is_true(uv.fs_mkdir(sub_dir, 493), "Failed to create src_dir_filter")

    local file1 = Path.join(src_dir, "file1.txt")
    local file2 = Path.join(src_dir, "file2.log")
    local file3 = Path.join(sub_dir, "file3.log")
    local file4 = Path.join(sub_dir, "file4.txt")
    local file5 = Path.join(sub_dir, "file5.txt")
    writefile(file1, "File 1 Content")
    writefile(file2, "File 2 Content")
    writefile(file3, "File 3 Content")
    writefile(file4, "File 4 Content")
    writefile(file5, "File 5 Content")

    cp(src_dir, dest_dir, {
      recursive = true,
      filter = function(type_, path_)
        if type_ == "file" and path_:match("%.log$") then
          return false
        end
        return true
      end,
    }, function(err, success)
      assert.is_true(success, "Failed to copy directory with filter: " .. tostring(err))
      assert.is_true(directory_exists(dest_dir), "Destination directory should exist")
      assert.is_true(file_exists(Path.join(dest_dir, "file1.txt")), "file1.txt should be copied")
      assert.is_false(file_exists(Path.join(dest_dir, "file2.log")), "file2.log should be excluded by filter")
      assert.is_true(directory_exists(dest_sub_dir), "Destination sub directory should exist")
      assert.is_false(file_exists(Path.join(dest_sub_dir, "file3.log")), "file3.log should be excluded by filter")
      assert.is_true(file_exists(Path.join(dest_sub_dir, "file4.txt")), "file4.txt should be copied")
      assert.is_true(file_exists(Path.join(dest_sub_dir, "file5.txt")), "file5.txt should be copied")
      done()
    end)
  end)

  async_it("should preserve timestamps when preserve_timestamps is true", function(done)
    local src_file = Path.join(temp_dir, "source_file_timestamp.txt")
    local dest_file = Path.join(cp_dir, "dest_file_timestamp.txt")
    writefile(src_file, "Timestamp Content")

    local current_time = os.time()
    uv.fs_utime(src_file, current_time, current_time)

    cp(src_file, dest_file, { preserve_timestamps = true }, function(err, success)
      assert.is_true(success, "Failed to copy file with preserved timestamps: " .. tostring(err))

      local stat_src = uv.fs_stat(src_file)
      local stat_dest = uv.fs_stat(dest_file)
      assert.is_not_nil(stat_src, "Source file stat should exist")
      assert.is_not_nil(stat_dest, "Destination file stat should exist")
      assert.are.equal(stat_src.atime.sec, stat_dest.atime.sec, "Access times should match")
      assert.are.equal(stat_src.mtime.sec, stat_dest.mtime.sec, "Modification times should match")
      done()
    end)
  end)
end)
