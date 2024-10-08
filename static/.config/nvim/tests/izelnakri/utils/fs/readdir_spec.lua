local FS = require("izelnakri.utils.fs")
local Path = require("izelnakri.utils.path")
local uv = vim.uv or vim.loop

-- Helper functions for tests
local function create_temp_dir()
  local tmp_dir = Path.join(os.tmpname())
  -- os.tmpname() may create a file; ensure it's a directory
  os.remove(tmp_dir)
  local success, err = FS.mkdir(tmp_dir)
  assert.is_true(success, "Failed to create temp directory: " .. tostring(err))
  return tmp_dir
end

local function create_file(file_path, content)
  return FS.writefile(file_path, content or "test")
end

local function create_symlink(target, link_path)
  local success, err = uv.fs_symlink(target, link_path)
  assert.is_true(success, "Failed to create symlink: " .. tostring(err))
end

describe("FS.readdir", function()
  local temp_dir

  before_each(function()
    temp_dir = create_temp_dir()
  end)

  after_each(function()
    -- Cleanup: Remove temp_dir if it still exists
    local function cleanup_dir(dir)
      local scan = uv.fs_scandir(dir)
      if scan then
        while true do
          local name, type_ = uv.fs_scandir_next(scan)
          if not name then
            break
          end
          if name ~= "." and name ~= ".." then
            local full_path = Path.join(dir, name)
            if type_ == "directory" then
              cleanup_dir(full_path)
              uv.fs_rmdir(full_path)
            elseif type_ == "file" or type_ == "link" then
              uv.fs_unlink(full_path)
            end
          end
        end
        uv.fs_rmdir(dir)
      end
    end

    cleanup_dir(temp_dir)
  end)

  describe("FS.readdir (sync)", function()
    it("should read a directory with only files", function()
      local file1 = Path.join(temp_dir, "file1.txt")
      local file2 = Path.join(temp_dir, "file2.txt")
      create_file(file1)
      create_file(file2)

      local entries, error = FS.readdir(temp_dir)

      assert.is_nil(error)
      table.sort(entries, function(a, b)
        return a.name < b.name
      end)
      assert.are.same({
        { name = temp_dir .. "/file1.txt", type = "file" },
        { name = temp_dir .. "/file2.txt", type = "file" },
      }, entries)
    end)

    it("should read a directory with only subdirectories", function()
      local sub_dir1 = Path.join(temp_dir, "sub_dir1")
      local sub_dir2 = Path.join(temp_dir, "sub_dir2")
      FS.mkdir(sub_dir1)
      FS.mkdir(sub_dir2)

      local entries = FS.readdir(temp_dir)
      table.sort(entries, function(a, b)
        return a.name < b.name
      end)
      assert.are.same({
        { name = temp_dir .. "/sub_dir1", type = "directory" },
        { name = temp_dir .. "/sub_dir2", type = "directory" },
      }, entries)
    end)

    it("should read a directory with mixed files and subdirectories", function()
      local sub_dir = Path.join(temp_dir, "sub_dir")
      FS.mkdir(sub_dir)
      local file1 = Path.join(temp_dir, "file1.txt")
      local file2 = Path.join(sub_dir, "file2.txt")
      create_file(file1)
      create_file(file2)

      local entries = FS.readdir(temp_dir)
      table.sort(entries, function(a, b)
        return a.name < b.name
      end)
      assert.are.same({
        { name = temp_dir .. "/file1.txt", type = "file" },
        { name = temp_dir .. "/sub_dir", type = "directory" },
      }, entries)
    end)

    it("should handle directories with similar prefixes", function()
      local dir1 = Path.join(temp_dir, "dir")
      local dir2 = Path.join(temp_dir, "directory")
      FS.mkdir(dir1)
      FS.mkdir(dir2)

      local entries = FS.readdir(temp_dir)
      table.sort(entries, function(a, b)
        return a.name < b.name
      end)
      assert.are.same({
        { name = temp_dir .. "/dir", type = "directory" },
        { name = temp_dir .. "/directory", type = "directory" },
      }, entries)
    end)

    it("should read a directory recursively", function()
      local sub_dir1 = Path.join(temp_dir, "sub_dir1")
      local sub_dir2 = Path.join(temp_dir, "sub_dir2")
      local sub_dir2_sub_dir = Path.join(sub_dir2, "sub_dir")
      FS.mkdir(sub_dir1)
      FS.mkdir(sub_dir2)
      FS.mkdir(sub_dir2_sub_dir)
      local file1 = Path.join(temp_dir, "file1.txt")
      local file2 = Path.join(sub_dir1, "file2.txt")
      local file3 = Path.join(sub_dir2, "file3.txt")
      local file4 = Path.join(sub_dir2, "file4.txt")
      local file5 = Path.join(sub_dir2_sub_dir, "file5.txt")

      create_file(file1)
      create_file(file2)
      create_file(file3)
      create_file(file4)
      create_file(file5)

      local entries = FS.readdir(temp_dir, { recursive = true })
      table.sort(entries, function(a, b)
        return a.name < b.name
      end)

      local temp_dir_path = String.slice(temp_dir, 2)
      assert.are.same({
        { name = temp_dir .. "/file1.txt", type = "file" },
        { name = temp_dir .. "/sub_dir1", type = "directory" },
        { name = temp_dir .. "/sub_dir1/file2.txt", type = "file" },
        { name = temp_dir .. "/sub_dir2", type = "directory" },
        { name = temp_dir .. "/sub_dir2/file3.txt", type = "file" },
        { name = temp_dir .. "/sub_dir2/file4.txt", type = "file" },
        { name = temp_dir .. "/sub_dir2/sub_dir", type = "directory" },
        { name = temp_dir .. "/sub_dir2/sub_dir/file5.txt", type = "file" },
      }, entries)
    end)

    it("should apply a filter function correctly", function()
      local sub_dir = Path.join(temp_dir, "sub_dir_filter")
      FS.mkdir(sub_dir)
      local file1 = Path.join(temp_dir, "file1_filter.txt")
      local file2 = Path.join(sub_dir, "file2_filter.log")
      create_file(file1)
      create_file(file2)

      local entries = FS.readdir(temp_dir, {
        filter = function(type_, path)
          return type_ == "file" and Path.extname(path) == "txt"
        end,
      })

      assert.are.same({
        { name = temp_dir .. "/file1_filter.txt", type = "file" },
      }, entries)
    end)

    it("should apply a filter function correctly with recursion", function()
      local sub_dir1 = Path.join(temp_dir, "sub_dir1")
      local sub_dir2 = Path.join(temp_dir, "sub_dir2")
      local sub_dir2_sub_dir = Path.join(sub_dir2, "sub_dir")
      FS.mkdir(sub_dir1)
      FS.mkdir(sub_dir2)
      FS.mkdir(sub_dir2_sub_dir)
      local file1 = Path.join(temp_dir, "file1.txt")
      local file2 = Path.join(sub_dir1, "file2.txt")
      local file3 = Path.join(sub_dir2, "file3.txt")
      local file4 = Path.join(sub_dir2, "file4.txt")
      local file5 = Path.join(sub_dir2_sub_dir, "file5.txt")

      create_file(file1)
      create_file(file2)
      create_file(file3)
      create_file(file4)
      create_file(file5)

      local entries = FS.readdir(temp_dir, {
        recursive = true,
        filter = function(type_, path)
          return type_ == "file" and String.includes(path, "sub_dir2")
        end,
      })
      table.sort(entries, function(a, b)
        return a.name < b.name
      end)

      assert.are.same({
        { name = temp_dir .. "/sub_dir2/file3.txt", type = "file" },
        { name = temp_dir .. "/sub_dir2/file4.txt", type = "file" },
        { name = temp_dir .. "/sub_dir2/sub_dir/file5.txt", type = "file" },
      }, entries)
    end)

    it("should limit recursion depth correctly", function()
      local dir_a = Path.join(temp_dir, "a")
      local dir_b = Path.join(dir_a, "b")
      local dir_c = Path.join(dir_b, "c")
      FS.mkdir(dir_a)
      create_file(Path.join(dir_a, "file_a.txt"))
      FS.mkdir(dir_b)
      FS.mkdir(dir_c)
      create_file(Path.join(dir_c, "file_c.txt"))

      local entries = FS.readdir(temp_dir, { recursive = true, depth = 1 })
      table.sort(entries, function(a, b)
        return a.name < b.name
      end)

      assert.are.same({
        { name = temp_dir .. "/a", type = "directory" },
        { name = temp_dir .. "/a/b", type = "directory" },
        { name = temp_dir .. "/a/file_a.txt", type = "file" },
      }, entries)
    end)

    it("should handle empty directories", function()
      local empty_dir = Path.join(temp_dir, "empty_dir")
      FS.mkdir(empty_dir)

      local entries, error = FS.readdir(empty_dir, options)
      assert.are.same({}, entries)
    end)

    it("should return an error for non-existent paths", function()
      local fake_path = Path.join(temp_dir, "non_existent")
      assert.has_errors(function()
        FS.readdir(fake_path)
      end, "Path does not exist: " .. fake_path)
    end)

    it("should handle symlinks correctly", function()
      local real_dir = Path.join(temp_dir, "real_dir")
      FS.mkdir(real_dir)
      create_symlink(real_dir, Path.join(temp_dir, "symlink_dir"))
      create_file(Path.join(real_dir, "file_in_real_dir.txt"))

      local entries = FS.readdir(temp_dir, {
        recursive = true,
        depth = 10,
      })
      table.sort(entries, function(a, b)
        return a.name < b.name
      end)
      assert.are.same({
        { name = temp_dir .. "/real_dir", type = "directory" },
        { name = temp_dir .. "/real_dir/file_in_real_dir.txt", type = "file" },
        { name = temp_dir .. "/symlink_dir", type = "link" },
      }, entries)
      local entries = FS.readdir(temp_dir)
      table.sort(entries, function(a, b)
        return a.name < b.name
      end)
      assert.are.same({
        { name = temp_dir .. "/real_dir", type = "directory" },
        { name = temp_dir .. "/symlink_dir", type = "link" },
      }, entries)
    end)
  end)

  describe("FS.readdir (async)", function()
    async_it("should read a directory with only files", function()
      local file1 = Path.join(temp_dir, "file1.txt")
      local file2 = Path.join(temp_dir, "file2.txt")
      create_file(file1)
      create_file(file2)

      FS.readdir(temp_dir, function(error, entries)
        assert.is_nil(error)
        table.sort(entries, function(a, b)
          return a.name < b.name
        end)
        assert.are.same({
          { name = temp_dir .. "/file1.txt", type = "file" },
          { name = temp_dir .. "/file2.txt", type = "file" },
        }, entries)

        done()
      end)
    end)

    async_it("should read a directory with only subdirectories", function()
      local sub_dir1 = Path.join(temp_dir, "sub_dir1")
      local sub_dir2 = Path.join(temp_dir, "sub_dir2")
      FS.mkdir(sub_dir1)
      FS.mkdir(sub_dir2)

      FS.readdir(temp_dir, function(err, entries)
        table.sort(entries, function(a, b)
          return a.name < b.name
        end)
        assert.are.same({
          { name = temp_dir .. "/sub_dir1", type = "directory" },
          { name = temp_dir .. "/sub_dir2", type = "directory" },
        }, entries)
        done()
      end)
    end)

    async_it("should read a directory with mixed files and subdirectories", function()
      local sub_dir = Path.join(temp_dir, "sub_dir")
      FS.mkdir(sub_dir)
      local file1 = Path.join(temp_dir, "file1.txt")
      local file2 = Path.join(sub_dir, "file2.txt")
      create_file(file1)
      create_file(file2)

      FS.readdir(temp_dir, function(err, entries)
        table.sort(entries, function(a, b)
          return a.name < b.name
        end)
        assert.are.same({
          { name = temp_dir .. "/file1.txt", type = "file" },
          { name = temp_dir .. "/sub_dir", type = "directory" },
        }, entries)
        done()
      end)
    end)

    async_it("should handle directories with similar prefixes", function()
      local dir1 = Path.join(temp_dir, "dir")
      local dir2 = Path.join(temp_dir, "directory")
      FS.mkdir(dir1)
      FS.mkdir(dir2)

      FS.readdir(temp_dir, function(err, entries)
        table.sort(entries, function(a, b)
          return a.name < b.name
        end)
        assert.are.same({
          { name = temp_dir .. "/dir", type = "directory" },
          { name = temp_dir .. "/directory", type = "directory" },
        }, entries)
        done()
      end)
    end)

    async_it("should read a directory recursively", function()
      local sub_dir1 = Path.join(temp_dir, "sub_dir1")
      local sub_dir2 = Path.join(temp_dir, "sub_dir2")
      local sub_dir2_sub_dir = Path.join(sub_dir2, "sub_dir")
      FS.mkdir(sub_dir1)
      FS.mkdir(sub_dir2)
      FS.mkdir(sub_dir2_sub_dir)
      local file1 = Path.join(temp_dir, "file1.txt")
      local file2 = Path.join(sub_dir1, "file2.txt")
      local file3 = Path.join(sub_dir2, "file3.txt")
      local file4 = Path.join(sub_dir2, "file4.txt")
      local file5 = Path.join(sub_dir2_sub_dir, "file5.txt")

      create_file(file1)
      create_file(file2)
      create_file(file3)
      create_file(file4)
      create_file(file5)

      FS.readdir(temp_dir, { recursive = true }, function(err, entries)
        table.sort(entries, function(a, b)
          return a.name < b.name
        end)

        assert.are.same({
          { name = temp_dir .. "/file1.txt", type = "file" },
          { name = temp_dir .. "/sub_dir1", type = "directory" },
          { name = temp_dir .. "/sub_dir1/file2.txt", type = "file" },
          { name = temp_dir .. "/sub_dir2", type = "directory" },
          { name = temp_dir .. "/sub_dir2/file3.txt", type = "file" },
          { name = temp_dir .. "/sub_dir2/file4.txt", type = "file" },
          { name = temp_dir .. "/sub_dir2/sub_dir", type = "directory" },
          { name = temp_dir .. "/sub_dir2/sub_dir/file5.txt", type = "file" },
        }, entries)
        done()
      end)
    end)

    async_it("should apply a filter function correctly", function()
      local sub_dir = Path.join(temp_dir, "sub_dir_filter")
      FS.mkdir(sub_dir)
      local file1 = Path.join(temp_dir, "file1_filter.txt")
      local file2 = Path.join(sub_dir, "file2_filter.log")
      create_file(file1)
      create_file(file2)

      FS.readdir(temp_dir, {
        filter = function(type_, path)
          return type_ == "file" and Path.extname(path) == "txt"
        end,
      }, function(err, entries)
        assert.are.same({
          { name = temp_dir .. "/file1_filter.txt", type = "file" },
        }, entries)
        done()
      end)
    end)

    async_it("should apply a filter function correctly with recursion", function()
      local sub_dir1 = Path.join(temp_dir, "sub_dir1")
      local sub_dir2 = Path.join(temp_dir, "sub_dir2")
      local sub_dir2_sub_dir = Path.join(sub_dir2, "sub_dir")
      FS.mkdir(sub_dir1)
      FS.mkdir(sub_dir2)
      FS.mkdir(sub_dir2_sub_dir)
      local file1 = Path.join(temp_dir, "file1.txt")
      local file2 = Path.join(sub_dir1, "file2.txt")
      local file3 = Path.join(sub_dir2, "file3.txt")
      local file4 = Path.join(sub_dir2, "file4.txt")
      local file5 = Path.join(sub_dir2_sub_dir, "file5.txt")

      create_file(file1)
      create_file(file2)
      create_file(file3)
      create_file(file4)
      create_file(file5)

      FS.readdir(temp_dir, {
        recursive = true,
        filter = function(type_, path)
          return type_ == "file" and String.includes(path, "sub_dir2")
        end,
      }, function(err, entries)
        table.sort(entries, function(a, b)
          return a.name < b.name
        end)

        assert.are.same({
          { name = temp_dir .. "/sub_dir2/file3.txt", type = "file" },
          { name = temp_dir .. "/sub_dir2/file4.txt", type = "file" },
          { name = temp_dir .. "/sub_dir2/sub_dir/file5.txt", type = "file" },
        }, entries)

        done()
      end)
    end)

    async_it("should limit recursion depth correctly", function()
      local dir_a = Path.join(temp_dir, "a")
      local dir_b = Path.join(dir_a, "b")
      local dir_c = Path.join(dir_b, "c")
      FS.mkdir(dir_a)
      create_file(Path.join(dir_a, "file_a.txt"))
      FS.mkdir(dir_b)
      FS.mkdir(dir_c)
      create_file(Path.join(dir_c, "file_c.txt"))

      FS.readdir(temp_dir, { recursive = true, depth = 1 }, function(err, entries)
        table.sort(entries, function(a, b)
          return a.name < b.name
        end)

        assert.are.same({
          { name = temp_dir .. "/a", type = "directory" },
          { name = temp_dir .. "/a/b", type = "directory" },
          { name = temp_dir .. "/a/file_a.txt", type = "file" },
        }, entries)
        done()
      end)
    end)

    async_it("should handle empty directories", function()
      local empty_dir = Path.join(temp_dir, "empty_dir")
      FS.mkdir(empty_dir)

      FS.readdir(empty_dir, function(err, entries)
        assert.are.equal(err, nil)
        assert.are.same({}, entries)
        done()
      end)
    end)

    async_it("should return an error for non-existent paths", function()
      local fake_path = Path.join(temp_dir, "non_existent")
      FS.readdir(fake_path, function(err, entries)
        assert.are.equal(err, "ENOENT: no such file or directory: " .. fake_path)
        assert.are.same(nil, entries)
        done()
      end)
    end)

    it("should handle symlinks correctly", function()
      local real_dir = Path.join(temp_dir, "real_dir")
      FS.mkdir(real_dir)
      create_symlink(real_dir, Path.join(temp_dir, "symlink_dir"))
      create_file(Path.join(real_dir, "file_in_real_dir.txt"))

      FS.readdir(temp_dir, {
        recursive = true,
        depth = 10,
      }, function(err, entries)
        table.sort(entries, function(a, b)
          return a.name < b.name
        end)
        assert.are.same({
          { name = temp_dir .. "/real_dir", type = "directory" },
          { name = temp_dir .. "/real_dir/file_in_real_dir.txt", type = "file" },
          { name = temp_dir .. "/symlink_dir", type = "link" },
        }, entries)
        FS.readdir(temp_dir, function(err, entries)
          table.sort(entries, function(a, b)
            return a.name < b.name
          end)
          assert.are.same({
            { name = temp_dir .. "/real_dir", type = "directory" },
            { name = temp_dir .. "/symlink_dir", type = "link" },
          }, entries)
          done()
        end)
      end)
    end)
  end)
end)
