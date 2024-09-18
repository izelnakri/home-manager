require("async.test")

local uv = vim.uv
local FS = require("izelnakri.utils.fs")

describe("FS.appendfile (async)", function()
  async_it("appends data to the file asynchronously and verifies the content", function(done)
    local path = "tests/izelnakri/tmp/test_async.txt"

    uv.fs_unlink(path)

    FS.appendfile(path, "Hello", nil, function(err, bytes)
      assert.is_nil(err)
      assert.is_true(bytes > 0)

      local fd = uv.fs_open(path, "r", 438)
      local stat = uv.fs_fstat(fd)
      local content = uv.fs_read(fd, stat.size, 0)
      uv.fs_close(fd)

      assert.are.equal("Hello", content)
      done()
    end)
  end)

  async_it("appends data to an existing file asynchronously and verifies the content", function(done)
    local path = "tests/izelnakri/tmp/test_async_append.txt"

    local fd = uv.fs_open(path, "w", 438)
    uv.fs_write(fd, "Existing data", -1)
    uv.fs_close(fd)

    FS.appendfile(path, " Appended data", nil, function(err, bytes)
      assert.is_nil(err)
      assert.is_true(bytes > 0)

      fd = uv.fs_open(path, "r", 438)
      local stat = uv.fs_fstat(fd)
      local content = uv.fs_read(fd, stat.size, 0)
      uv.fs_close(fd)

      assert.are.equal("Existing data Appended data", content)
      done()
    end)
  end)

  async_it("flushes the file content to disk if the flush option is set", function(done)
    local path = "tests/izelnakri/tmp/test_flush_async.txt"

    uv.fs_unlink(path)

    FS.appendfile(path, "Hello", { flush = true }, function(err, bytes)
      assert.is_nil(err)
      assert.is_true(bytes > 0)

      local fd = uv.fs_open(path, "r", 438)
      local stat = uv.fs_fstat(fd)
      local content = uv.fs_read(fd, stat.size, 0)
      uv.fs_close(fd)

      assert.are.equal("Hello", content)
      done()
    end)
  end)

  async_it("does not write anything if data is an empty string asynchronously", function(done)
    local path = "tests/izelnakri/tmp/test_empty_async.txt"

    uv.fs_unlink(path)

    FS.appendfile(path, "", nil, function(err, bytes)
      assert.is_nil(err)
      assert.is_true(bytes == 0)

      local fd = uv.fs_open(path, "r", 438)
      local stat = uv.fs_fstat(fd)
      assert.is_true(stat.size == 0)
      uv.fs_close(fd)
      done()
    end)
  end)
end)

describe("FS.appendfile (sync)", function()
  it("appends data to the file asynchronously and verifies the content", function(done)
    local path = "tests/izelnakri/tmp/test_sync.txt"

    uv.fs_unlink(path)

    local bytes = FS.appendfile(path, "Hello", nil)
    assert.is_true(bytes > 0)

    local fd = uv.fs_open(path, "r", 438)
    local stat = uv.fs_fstat(fd)
    local content = uv.fs_read(fd, stat.size, 0)
    uv.fs_close(fd)

    assert.are.equal("Hello", content)
  end)

  it("appends data to an existing file asynchronously and verifies the content", function(done)
    local path = "tests/izelnakri/tmp/test_sync_append.txt"

    local fd = uv.fs_open(path, "w", 438)
    uv.fs_write(fd, "Existing data", -1)
    uv.fs_close(fd)

    local bytes = FS.appendfile(path, " Appended data", nil)
    assert.is_true(bytes > 0)

    fd = uv.fs_open(path, "r", 438)
    local stat = uv.fs_fstat(fd)
    local content = uv.fs_read(fd, stat.size, 0)
    uv.fs_close(fd)

    assert.are.equal("Existing data Appended data", content)
  end)

  it("flushes the file content to disk if the flush option is set", function(done)
    local path = "tests/izelnakri/tmp/test_flush_sync.txt"

    uv.fs_unlink(path)

    local bytes = FS.appendfile(path, "Hello", { flush = true })
    assert.is_true(bytes > 0)

    local fd = uv.fs_open(path, "r", 438)
    local stat = uv.fs_fstat(fd)
    local content = uv.fs_read(fd, stat.size, 0)
    uv.fs_close(fd)

    assert.are.equal("Hello", content)
  end)

  it("does not write anything if data is an empty string synchronously", function(done)
    local path = "tests/izelnakri/tmp/test_empty_sync.txt"

    uv.fs_unlink(path)

    local bytes = FS.appendfile(path, "", nil)
    assert.is_true(bytes == 0)

    local fd = uv.fs_open(path, "r", 438)
    local stat = uv.fs_fstat(fd)
    assert.is_true(stat.size == 0)
    uv.fs_close(fd)
  end)
end)
