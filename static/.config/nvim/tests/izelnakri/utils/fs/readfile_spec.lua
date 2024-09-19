require("async.test")

local uv = vim.uv
local FS = require("izelnakri.utils.fs")

local TMP_FOLDER_PATH = "tests/izelnakri/tmp/"

describe("FS.readfile (sync)", function()
  it("should read a file successfully (sync)", function()
    FS.writefile(TMP_FOLDER_PATH .. "testfile.txt", "this is file content")

    local content = FS.readfile(TMP_FOLDER_PATH .. "testfile.txt")
    assert.is_true(type(content) == "string")
    assert.is_equal(content, "this is file content")
  end)

  it("should return an error if the file does not exist (sync)", function()
    assert.has_error(function()
      FS.readfile(TMP_FOLDER_PATH .. "nonexistent.txt")
    end)
  end)

  it("should handle empty files (sync)", function()
    FS.writefile(TMP_FOLDER_PATH .. "emptyfile.txt", "")

    local content = FS.readfile(TMP_FOLDER_PATH .. "emptyfile.txt")
    assert.is_equal(content, "")
  end)

  it("should return an error on read failure", function()
    local filepath = TMP_FOLDER_PATH .. "readfailure.txt"
    uv.fs_unlink(filepath)
    FS.writefile(filepath, "This file should be locked")

    assert(uv.fs_chmod(filepath, 000))
    assert.has_error(function()
      FS.readfile(filepath)
    end)

    assert(uv.fs_chmod(filepath, 438))
    uv.fs_unlink(filepath)
  end)
end)

describe("FS.readfile (async)", function()
  async_it("should read a file successfully", function(done)
    FS.writefile(TMP_FOLDER_PATH .. "testfile.txt", "this is file content")

    FS.readfile(TMP_FOLDER_PATH .. "testfile.txt", function(err, content)
      assert.is_nil(err)
      assert.is_true(type(content) == "string")
      assert.is_equal(content, "this is file content")

      done()
    end)
  end)

  async_it("should return an error if the file does not exist", function(done)
    FS.readfile(TMP_FOLDER_PATH .. "nonexistent.txt", function(err, content)
      assert.is_true(type(err) == "string")
      assert.matches("Error opening file", err)
      done()
    end)
  end)

  async_it("should handle empty files", function()
    FS.writefile(TMP_FOLDER_PATH .. "emptyfile.txt", "")

    FS.readfile(TMP_FOLDER_PATH .. "emptyfile.txt", function(err, content)
      assert.is_nil(err)
      assert.is_equal(content, "")
      done()
    end)
  end)

  async_it("should return an error on read failure", function()
    local filepath = TMP_FOLDER_PATH .. "readfailure.txt"
    FS.writefile(filepath, "This file should be locked")

    assert(uv.fs_chmod(filepath, 000))
    FS.readfile(filepath, function(err, content)
      assert.is_nil(conten)
      assert.matches("Error opening file", err)
      assert(uv.fs_chmod(filepath, 438))
      uv.fs_unlink(filepath)
      done()
    end)
  end)
end)
