-- Path.relative(dir, entry_path)
local Path = require("izelnakri.utils.path")
local String = require("izelnakri.utils.string")

describe("Path module", function()
  it("absname", function()
    local cwd = vim.uv.cwd()
    -- Normal cases
    assert.are.equal(cwd .. "/file.txt", Path.absname("file.txt"))
    assert.are.equal("/home/user/file.txt", Path.absname("file.txt", "/home/user"))
    assert.are.equal("/file.txt", Path.absname("/file.txt", "/home/user"))

    -- Edge cases
    assert.are.equal("/", Path.absname("/", "/")) -- Root path case
    assert.are.equal(cwd, Path.absname("")) -- Empty path should return cwd
    assert.are.equal(cwd, Path.absname(".")) -- Current directory
    assert.are.equal(Path.dirname(cwd), Path.absname("..")) -- Parent directory
  end)

  it("basename", function()
    -- Normal cases
    assert.are.equal("file.txt", Path.basename("/home/user/file.txt"))
    assert.are.equal("file", Path.basename("/home/user/file"))

    -- Edge cases
    assert.are.equal("", Path.basename("/home/user/")) -- Trailing slash
    assert.are.equal("", Path.basename("/")) -- Root directory
    assert.are.equal("user", Path.basename("/home/user")) -- No trailing slash
  end)

  it("dirname", function()
    -- Normal cases
    assert.are.equal("/home/user", Path.dirname("/home/user/file.txt"))
    assert.are.equal("/", Path.dirname("/file.txt"))

    -- Edge cases
    assert.are.equal("/", Path.dirname("/")) -- Root path
    assert.are.equal("/home/user", Path.dirname("/home/user/")) -- Trailing slash
    assert.are.equal("/home", Path.dirname("/home/user")) -- No trailing slash
  end)

  it("join", function()
    -- Normal cases
    assert.are.equal("/home/user/file.txt", Path.join("/home", "user", "file.txt"))
    assert.are.equal("/home/user/file.txt", Path.join("/home", "/user/", "file.txt"))
    assert.are.equal("/file.txt", Path.join("/", "file.txt"))

    -- Edge cases
    assert.are.equal("/home", Path.join("/home")) -- Single argument
    assert.are.equal("/", Path.join("/", "")) -- Empty last part
    assert.are.equal("home/user", Path.join("home", "user")) -- Relative paths
    assert.are.equal("home/user/", Path.join("home", "user", "")) -- Trailing slash
  end)

  it("extname", function()
    -- Normal cases
    assert.are.equal("txt", Path.extname("/home/user/file.txt"))
    assert.are.equal("", Path.extname("/home/user/file"))

    -- Edge cases
    -- assert.are.equal("", Path.extname("/home/user/.hiddenfile")) -- Hidden file -- TODO: fix this
    assert.are.equal("gz", Path.extname("/home/user/file.tar.gz")) -- Double extension
    assert.are.equal("", Path.extname("/")) -- Root directory
    assert.are.equal("", Path.extname("")) -- Empty path
  end)

  it("filename", function()
    -- Normal cases
    assert.are.equal("file", Path.filename("/home/user/file.txt"))
    assert.are.equal("file", Path.filename("/home/user/file"))

    -- Edge cases
    -- assert.are.equal(".hiddenfile", Path.filename("/home/user/.hiddenfile")) -- Hidden file -- TODO: fix this
    assert.are.equal("file.tar", Path.filename("/home/user/file.tar.gz")) -- Double extension
    assert.are.equal("", Path.filename("/home/user/")) -- Trailing slash
    assert.are.equal("", Path.filename("/")) -- Root directory
    assert.are.equal("", Path.filename("")) -- Empty path
  end)

  it("is_absolute", function()
    -- Normal cases
    assert.is_true(Path.is_absolute("/home/user/file.txt"))
    assert.is_false(Path.is_absolute("file.txt"))

    -- Edge cases
    assert.is_true(Path.is_absolute("/")) -- Root directory
    assert.is_false(Path.is_absolute("")) -- Empty path
  end)

  it("parents", function()
    -- Normal cases
    local parents = Path.parents("/home/user/file.txt")
    assert.same({ "/home/user", "/home", "/" }, parents:totable())

    -- Edge cases
    local parents_root = Path.parents("/") -- Root directory has no parent
    assert.same({}, parents_root:totable())

    local parents_empty = Path.parents("")
    assert.same({ "." }, parents_empty:totable())
  end)

  it("split", function()
    -- Normal cases
    assert.same({ "/", "home", "user", "file.txt" }, Path.split("/home/user/file.txt"))
    assert.same({ "home", "user", "file.txt" }, Path.split("home/user/file.txt"))

    -- Edge cases
    -- assert.same({ "/" }, Path.split("/")) -- Root directory -- TODO: Fix this?
    -- assert.same({ "" }, Path.split("")) -- Empty path -- TODO: Fix this?
    assert.same({ "/", "home", "user", "" }, Path.split("/home/user/")) -- Trailing slash
    assert.same({ ".", "file.txt" }, Path.split("./file.txt")) -- Relative current directory
  end)

  -- TODO: Build this
  -- -- Uncomment and implement the relative function, then test it
  -- -- it("relative", function()
  -- --   assert.are.equal("user/file.txt", Path.relative("/home", "/home/user/file.txt"))
  -- --   assert.are.equal("../user/file.txt", Path.relative("/var", "/var/user/file.txt"))
  -- --   assert.are.equal("file.txt", Path.relative("/home/user", "/home/user/file.txt"))
  -- -- end)
end)
