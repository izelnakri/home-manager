require("async.test")

local uv = vim.uv
local FS = require("izelnakri.utils.fs")

describe("FS.writefile (async)", function()
  async_it("writes data to the file asynchronously and verifies the content", function(done)
    local path = "tests/izelnakri/tmp/test_async.txt"

    uv.fs_unlink(path)

    FS.writefile(path, "Hello", function(err, bytes)
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

  async_it("writes data to an existing file asynchronously and verifies the content", function(done)
    local path = "tests/izelnakri/tmp/test_async_write.txt"

    local fd = uv.fs_open(path, "w", 438)
    uv.fs_write(fd, "Existing data", -1)
    uv.fs_close(fd)

    FS.writefile(path, " writeed data", function(err, bytes)
      assert.is_nil(err)
      assert.is_true(bytes > 0)

      fd = uv.fs_open(path, "r", 438)
      local stat = uv.fs_fstat(fd)
      local content = uv.fs_read(fd, stat.size, 0)
      uv.fs_close(fd)

      assert.are.equal(" writeed data", content)
      done()
    end)
  end)

  async_it("flushes the file content to disk if the flush option is set", function(done)
    local path = "tests/izelnakri/tmp/test_flush_async.txt"

    uv.fs_unlink(path)

    FS.writefile(path, "Hello", { flush = true }, function(err, bytes)
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

    FS.writefile(path, "", function(err, bytes)
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

describe("FS.writefile (sync)", function()
  it("writes data to the file asynchronously and verifies the content", function(done)
    local path = "tests/izelnakri/tmp/test_sync.txt"

    uv.fs_unlink(path)

    local bytes = FS.writefile(path, "Hello")
    assert.is_true(bytes > 0)

    local fd = uv.fs_open(path, "r", 438)
    local stat = uv.fs_fstat(fd)
    local content = uv.fs_read(fd, stat.size, 0)
    uv.fs_close(fd)

    assert.are.equal("Hello", content)
  end)

  it("writes data to an existing file asynchronously and verifies the content", function(done)
    local path = "tests/izelnakri/tmp/test_sync_write.txt"

    local fd = uv.fs_open(path, "w", 438)
    uv.fs_write(fd, "Existing data", -1)
    uv.fs_close(fd)

    local bytes = FS.writefile(path, " writeed data")
    assert.is_true(bytes > 0)

    fd = uv.fs_open(path, "r", 438)
    local stat = uv.fs_fstat(fd)
    local content = uv.fs_read(fd, stat.size, 0)
    uv.fs_close(fd)

    assert.are.equal(" writeed data", content)
  end)

  it("flushes the file content to disk if the flush option is set", function(done)
    local path = "tests/izelnakri/tmp/test_flush_sync.txt"

    uv.fs_unlink(path)

    local bytes = FS.writefile(path, "Hello", { flush = true })
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

    local bytes = FS.writefile(path, "")
    assert.is_true(bytes == 0)

    local fd = uv.fs_open(path, "r", 438)
    local stat = uv.fs_fstat(fd)
    assert.is_true(stat.size == 0)
    uv.fs_close(fd)
  end)
end)
