-- spec/fs_blocking_spec.lua
local FS = require("izelnakri.utils.fs")

describe("FS Module methods: blocking", function()
  local temp_file = "temp_blocking_test.txt"
  local temp_dir = "temp_blocking_dir"
  local temp_file_in_dir = temp_dir .. "/test.txt"

  before_each(function()
    -- NOTE: make it writeFile
    local fd = assert(FS.open(temp_file, "w", 438)) -- 438 = octal 0666
    FS.write(fd, "hello world")
    FS.close(fd)

    assert(FS.mkdir(temp_dir, 493)) -- 493 = octal 0755
    -- NOTE: make it rmdir
    local fd_dir = assert(FS.open(temp_file_in_dir, "w", 438))
    FS.write(fd_dir, "file in dir")
    FS.close(fd_dir)
  end)

  after_each(function()
    FS.unlink(temp_file)
    FS.unlink(temp_file_in_dir)
    FS.rmdir(temp_dir)
  end)

  it("FS.open: should open and read a file", function()
    local fd = assert(FS.open(temp_file, "r", 438))
    local stat = assert(FS.fstat(fd))
    local data = assert(FS.read(fd, stat.size, 0))
    assert.are.equal("hello world", data)
    FS.close(fd)
  end)

  it("FS.write: should write to a file", function()
    local fd = assert(FS.open(temp_file, "w", 438))
    assert(FS.write(fd, "new content"))
    FS.close(fd)

    fd = assert(FS.open(temp_file, "r", 438))
    local stat = assert(FS.fstat(fd))
    local data = assert(FS.read(fd, stat.size, 0))
    assert.are.equal("new content", data)
    FS.close(fd)
  end)

  it("FS.stat: should stat a file", function()
    local stat = assert(FS.stat(temp_file))
    assert.is_table(stat)
    assert.is_number(stat.size)
  end)

  it("FS.rename: should rename a file", function()
    local new_name = "temp_blocking_test_renamed.txt"
    assert(FS.rename(temp_file, new_name))
    assert(FS.stat(new_name))

    -- Rename back to original
    assert(FS.rename(new_name, temp_file))
  end)

  it("FS.unlink: should unlink a file", function()
    local fd = assert(FS.open(temp_file, "r", 438))
    FS.close(fd)
    assert(FS.unlink(temp_file))
  end)

  it("FS.rmdir: should create and remove a directory", function()
    local dir_name = "temp_blocking_test_dir"
    assert(FS.mkdir(dir_name, 493)) -- 493 = octal 0755
    local stat = assert(FS.stat(dir_name))
    assert.is_table(stat)
    assert.is_true(stat.type == "directory")
    assert(FS.rmdir(dir_name))
  end)

  it("FS.scandir: should scan a directory", function()
    local entries = {}
    local req = FS.scandir(temp_dir)
    while true do
      local name, typ = FS.scandir_next(req)
      if not name then
        break
      end
      table.insert(entries, { name, typ })
    end
    assert.are.same({ { "test.txt", "file" } }, entries)
  end)

  -- TODO: There is no such func as uv.new_buf
  -- it("should read a file into a buffer", function()
  --   local fd = assert(FS.open(temp_file, "r", 438))
  --
  --   local buffer = uv.new_buf(11)
  --
  --   assert(FS.read(fd, buffer, 0))
  --   assert.are.equal("hello world", buffer:to_string())
  --   FS.close(fd)
  -- end)

  -- TODO: There is no such func as uv.new_buf
  -- it("should write a buffer into a file", function()
  --   local fd = assert(FS.open(temp_file, "w", 438))
  --   local buffer = uv.new_buf("buffer content")
  --   assert(FS.write(fd, buffer))
  --   FS.close(fd)
  --
  --   fd = assert(FS.open(temp_file, "r", 438))
  --   local stat = assert(FS.fstat(fd))
  --   local data = assert(FS.read(fd, stat.size, 0))
  --   assert.are.equal("buffer content", data)
  --   FS.close(fd)
  -- end)
end)
