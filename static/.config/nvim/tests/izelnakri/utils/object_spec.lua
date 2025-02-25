-- In rust keys, values lazy(iterator) | there is also into_,
-- in elixir not lazy
-- in JS not lazy

local Object = require("izelnakri.utils.object")

describe("Object module", function()
  describe("assign", function()
    it("should merge two objects", function()
      local obj1 = { a = 1, b = 2 }
      local obj2 = { b = 3, c = 4 }
      assert.are.same(Object.assign({}, obj1, obj2), { a = 1, b = 3, c = 4 })
    end)
  end)

  it("entries", function()
    local obj = { name = "Izel", surname = "Nakri", city = "Madrid" }
    local first_entries = Object.entries(obj)

    local entries = {}
    local keys = {}
    local values = {}
    for key, value in first_entries do
      table.insert(keys, key)
      table.insert(values, value)
      table.insert(entries, { key, value })
    end
    table.sort(keys)
    table.sort(values)

    assert.are.same(first_entries:totable(), {})
    assert.are.same(Object.entries(obj):totable(), entries)
    assert.are.same(keys, { "city", "name", "surname" })
    assert.are.same(values, { "Izel", "Madrid", "Nakri" })
  end)

  describe("from_entries", function()
    it("should create an object from key-value pairs", function()
      local entries = { { "a", 1 }, { "b", 2 }, { "c", 3 } }
      local result = Object.from_entries(entries)
      assert.are.same({ a = 1, b = 2, c = 3 }, result)
    end)
  end)

  describe("keys", function()
    it("should return an iterator of keys", function()
      local obj = { a = 1, b = 2, c = 3 }
      local expected = { "a", "b", "c" }
      local result = {}
      for key in Object.keys(obj) do
        table.insert(result, key)
      end
      table.sort(result)

      assert.are.same(result, expected)
    end)
  end)

  describe("has_key", function()
    it("should return true if the key exists", function()
      local obj = { a = 1, b = { c = 2 } }
      assert.is_true(Object.has_key(obj, "a"))
      assert.is_true(Object.has_key(obj, "b.c"))
    end)

    it("should return false if the key does not exist", function()
      local obj = { a = 1, b = { c = 2 } }
      assert.is_false(Object.has_key(obj, "d"))
      assert.is_false(Object.has_key(obj, "b.d"))
    end)
  end)

  describe("values", function()
    it("should return an iterator of values", function()
      local obj = { a = 1, b = 2, c = 3 }
      local expected = { 1, 2, 3 }
      local result = {}

      for value in Object.values(obj) do
        table.insert(result, value)
      end

      table.sort(result)

      assert.are.same(result, expected)
    end)
  end)

  describe("length", function()
    it("should return the number of keys", function()
      local obj = { a = 1, b = 2, c = 3 }
      assert.are.equal(Object.length(obj), 3)
    end)
  end)

  describe("get", function()
    it("should return the value of the key", function()
      local obj = { a = 1, b = { c = 2 } }
      assert.are.equal(Object.get(obj, "a"), 1)
      assert.are.equal(Object.get(obj, "b.c"), 2)
    end)

    it("should return nil if the key does not exist", function()
      local obj = { a = 1, b = { c = 2 } }
      assert.is_nil(Object.get(obj, "d"))
      assert.is_nil(Object.get(obj, "b.d"))
    end)
  end)

  describe("set", function()
    it("should set the value of the key", function()
      local obj = { a = 1, b = { c = 2 } }
      Object.set(obj, "a", 3)
      Object.set(obj, "b.c", 4)

      assert.are.equal(obj.a, 3)
      assert.are.equal(obj.b.c, 4)
    end)

    it("should create nested tables if they do not exist", function()
      local obj = { a = 1 }
      Object.set(obj, "b.c", 2)

      assert.are.same(obj, { a = 1, b = { c = 2 } })
    end)
  end)

  describe("insert", function()
    it("should insert a key-value pair into the object", function()
      local obj = { a = 1 }

      assert.are.same(Object.insert(obj, "b", 2), { a = 1, b = 2 })
    end)
  end)

  describe("remove", function()
    it("should remove a key from the object", function()
      local obj = { a = 1, b = { c = 2 } }

      assert.is_true(Object.has_key(obj, "a"))
      assert.is_true(Object.has_key(obj, "b.c"))

      Object.remove(obj, "a")
      Object.remove(obj, "b.c")

      assert.is_false(Object.has_key(obj, "a"))
      assert.is_false(Object.has_key(obj, "b.c"))

      assert.is_nil(obj.a)
      assert.is_nil(obj.b.c)

      assert.are.same(obj, { b = {} })
    end)

    it("should do nothing if the key does not exist", function()
      local obj = { a = 1 }
      Object.remove(obj, "b")

      assert.are.same(obj, { a = 1 })
    end)
  end)
end)
