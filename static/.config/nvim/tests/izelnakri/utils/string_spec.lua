local String = require("izelnakri.utils.string")

describe("String Utilities", function()
  it("at", function()
    assert.are.equal("h", String.at("hello", 1))
    assert.are.equal("o", String.at("hello", -1))
  end)

  it("char_code_at", function()
    assert.are.equal(104, String.char_code_at("hello", 1))
    assert.are.equal(111, String.char_code_at("hello", -1))
  end)

  it("concat", function()
    assert.are.equal("hello world", String.concat("hello ", "world"))
  end)

  it("ends_with", function()
    assert.is_true(String.ends_with("hello", "lo"))
    assert.is_false(String.ends_with("hello", "he"))
  end)

  it("includes", function()
    assert.is_true(String.includes("hello", "ell"))
    assert.is_false(String.includes("hello", "xyz"))
  end)

  it("index_of", function()
    assert.are.equal(2, String.index_of("hello", "e"))
    assert.are.equal(nil, String.index_of("hello", "x"))
  end)

  it("last_index_of", function()
    assert.are.equal(4, String.last_index_of("hello", "l"))
    assert.are.equal(nil, String.last_index_of("hello", "x"))
  end)

  it("match", function()
    assert.same({ "ell" }, String.match("hello", "ell"))
  end)

  it("match_all", function()
    local matches = {}
    for s in String.match_all("hello hello", "l") do
      table.insert(matches, s)
    end
    assert.same({ 3, 4, 9, 10 }, matches)
  end)

  it("pad_end", function()
    assert.are.equal("hello   ", String.pad_end("hello", 8, " "))
    assert.are.equal("hello!!!", String.pad_end("hello", 8, "!"))
  end)

  it("pad_start", function()
    assert.are.equal("   hello", String.pad_start("hello", 8, " "))
    assert.are.equal("!!!hello", String.pad_start("hello", 8, "!"))
  end)

  it("rep", function()
    assert.are.equal("abcabcabc", String.rep("abc", 3))
  end)

  it("replace", function()
    assert.are.equal("hxllo", String.replace("hello", "e", "x"))
    assert.are.equal("hxo", String.replace("hello", "ell", "x"))
    -- TODO: Problem arises at "-"
    assert.are.equal(
      "logs/refs/remotes/origin/main",
      String.replace(
        "/home/izelnakri/.config/home-manager/.git/logs/refs/remotes/origin/main",
        "/home/izelnakri/.config/home-manager/.git/",
        "",
        true
      )
    )
  end)

  it("replace_all", function()
    assert.are.equal("hexxo", String.replace_all("hello", "l", "x"))
  end)

  it("search", function()
    assert.are.equal(3, String.search("hello", "l"))
    assert.are.equal(nil, String.search("hello", "x"))
  end)

  it("slice", function()
    -- NOTE: in JS: DONT INCLUDE THE END INDEX, START INDEX ALWAYS GETS INCLUDED
    assert.are.equal("el", String.slice("hello", 2, 4)) -- JS: el
    assert.are.equal("ello", String.slice("hello", 2, 10)) -- JS: ello
    assert.are.equal("llo", String.slice("hello", 3)) -- JS: llo
    assert.are.equal("el", String.slice("hello", -4, -2)) -- JS: el
    assert.are.equal("el", String.slice("hello", -4, 4)) -- JS: el
    assert.are.equal("lo", String.slice("hello", -2)) -- JS: lo
    assert.are.equal("", String.slice("hello", 4, 2)) -- JS: ''
    assert.are.equal("", String.slice("hello", 2, 2)) -- JS: ''
    assert.are.equal("", String.slice("hello", 10, 12)) -- JS: ''
    assert.are.equal("hell", String.slice("hello", -10, 5)) -- JS: hell
    assert.are.equal("hel", String.slice("hello", -10, -2)) -- JS: hel
    assert.are.equal("hel", String.slice("hello", 0, 4)) -- JS: hel
    assert.are.equal("hel", String.slice("hello", 1, 4)) -- JS: hel
    assert.are.equal("hello", String.slice("hello", 0)) -- JS: hello
    assert.are.equal("hello", String.slice("hello", 1)) -- JS: hello
    assert.are.equal("hello", String.slice("hello")) -- JS: hello
    assert.are.equal("", String.slice("hello", 10)) -- JS: ''
    assert.are.equal("el", String.slice("hello", -4, 4)) -- JS: el
  end)

  it("split", function()
    assert.same({ "a", "b", "c" }, String.split("a,b,c", ","))
  end)

  it("starts_with", function()
    assert.is_true(String.starts_with("hello", "he"))
    assert.is_false(String.starts_with("hello", "lo"))
  end)

  it("substring", function()
    assert.are.equal("ell", String.substring("hello", 2, 4))
    assert.are.equal("lo", String.substring("hello", 4))
  end)

  it("to_lower_case", function()
    assert.are.equal("hello", String.to_lower_case("HELLO"))
  end)

  it("to_upper_case", function()
    assert.are.equal("HELLO", String.to_upper_case("hello"))
  end)

  it("trim", function()
    assert.are.equal("hello", String.trim("  hello  "))
  end)

  it("trim_start", function()
    assert.are.equal("hello  ", String.trim_start("  hello  "))
  end)

  it("trim_end", function()
    assert.are.equal("  hello", String.trim_end("  hello  "))
  end)

  it("length", function()
    assert.are.equal(5, String.length("hello"))
  end)
end)
