local memory_store = require("anchor.memory_store")

-- Counter to ensure unique buffer names
local buffer_counter = 0

-- Utility function to create a fake buffer
local function create_fake_buffer(name)
  buffer_counter = buffer_counter + 1
  local unique_name = (name or "testbuf") .. "_" .. buffer_counter
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buf, unique_name)
  return buf
end

describe("Anchor Memory Store", function()
  before_each(function()
    -- Clear all anchors before each test
    memory_store.clear_all_anchors()
  end)

  it("should add and list anchors in the same buffer", function()
    local buf = create_fake_buffer("test1")
    vim.api.nvim_set_current_buf(buf)

    -- Add anchors
    memory_store.add_anchor(10, 1)
    memory_store.add_anchor(20, 2)

    -- List anchors
    local anchors = memory_store.get_anchors()
    assert.equals(2, #anchors)
    assert.equals(10, anchors[1].row)
    assert.equals(20, anchors[2].row)
  end)

  it("should maintain separate anchor lists for different buffers", function()
    local buf1 = create_fake_buffer("test1")
    local buf2 = create_fake_buffer("test2")

    vim.api.nvim_set_current_buf(buf1)
    memory_store.add_anchor(10, 1)
    
    vim.api.nvim_set_current_buf(buf2)
    memory_store.add_anchor(30, 2)

    -- List anchors for buffer 1
    vim.api.nvim_set_current_buf(buf1)
    local anchors1 = memory_store.get_anchors()
    assert.equals(1, #anchors1)
    assert.equals(10, anchors1[1].row)

    -- List anchors for buffer 2
    vim.api.nvim_set_current_buf(buf2)
    local anchors2 = memory_store.get_anchors()
    assert.equals(1, #anchors2)
    assert.equals(30, anchors2[1].row)
  end)

  it("should remove specific anchors by index", function()
    local buf = create_fake_buffer("test3")
    vim.api.nvim_set_current_buf(buf)

    memory_store.add_anchor(10, 1)
    local index2 = memory_store.add_anchor(20, 2)
    
    -- Remove the second anchor
    memory_store.remove_anchor(index2)

    -- List anchors
    local anchors = memory_store.get_anchors()
    assert.equals(1, #anchors)
    assert.equals(10, anchors[1].row)
  end)

  it("should clear anchors for a specific buffer", function()
    local buf = create_fake_buffer("test4")
    vim.api.nvim_set_current_buf(buf)
    memory_store.add_anchor(10, 1)
    memory_store.add_anchor(20, 2)
    
    -- Clear anchors
    memory_store.clear_anchors()

    -- List anchors
    local anchors = memory_store.get_anchors()
    assert.equals(0, #anchors)
  end)

  it("should handle anchors across multiple buffers", function()
    local buf1 = create_fake_buffer("test5")
    local buf2 = create_fake_buffer("test6")

    vim.api.nvim_set_current_buf(buf1)
    memory_store.add_anchor(10, 1)
    
    vim.api.nvim_set_current_buf(buf2)
    memory_store.add_anchor(30, 2)

    -- Get all anchors across buffers
    local all_anchors = memory_store.get_all_anchors()
    assert.equals(2, #all_anchors)
    assert.equals(buf1, all_anchors[1].bufnr)
    assert.equals(10, all_anchors[1].row)
    assert.equals(buf2, all_anchors[2].bufnr)
    assert.equals(30, all_anchors[2].row)
  end)

  it("should handle anchor labels correctly", function()
    local buf = create_fake_buffer("labeled_test")
    vim.api.nvim_set_current_buf(buf)

    -- Add anchor with label
    memory_store.add_anchor(15, 5, "important_spot")
    
    local anchors = memory_store.get_anchors()
    assert.equals(1, #anchors)
    assert.equals(15, anchors[1].row)
    assert.equals(5, anchors[1].col)
    assert.equals("important_spot", anchors[1].label)
  end)

  it("should validate input parameters", function()
    local buf = create_fake_buffer("validation_test")
    vim.api.nvim_set_current_buf(buf)

    -- Test invalid row (should error)
    local success, err = pcall(memory_store.add_anchor, 0, 1)
    assert.is_false(success)
    assert.is_true(string.find(err, "Row must be a positive number") ~= nil)

    -- Test invalid column (should error)
    success, err = pcall(memory_store.add_anchor, 1, -1)
    assert.is_false(success)
    assert.is_true(string.find(err, "Column must be a non-negative number") ~= nil)
  end)

  it("should return correct anchor count", function()
    local buf = create_fake_buffer("count_test")
    vim.api.nvim_set_current_buf(buf)

    assert.equals(0, memory_store.get_anchor_count())
    
    memory_store.add_anchor(10, 1)
    assert.equals(1, memory_store.get_anchor_count())
    
    memory_store.add_anchor(20, 2)
    assert.equals(2, memory_store.get_anchor_count())
    
    memory_store.remove_anchor(1)
    assert.equals(1, memory_store.get_anchor_count())
  end)

  it("should handle buffer cleanup correctly", function()
    local buf1 = create_fake_buffer("cleanup_test1")
    local buf2 = create_fake_buffer("cleanup_test2")

    vim.api.nvim_set_current_buf(buf1)
    memory_store.add_anchor(10, 1)
    
    vim.api.nvim_set_current_buf(buf2)
    memory_store.add_anchor(20, 2)

    -- Cleanup buffer 1
    memory_store.cleanup_buffer(buf1)
    
    -- Buffer 1 should have no anchors, buffer 2 should still have anchors
    assert.equals(0, memory_store.get_anchor_count(buf1))
    assert.equals(1, memory_store.get_anchor_count(buf2))
  end)

  it("should check if buffer has anchors", function()
    local buf = create_fake_buffer("has_anchors_test")
    vim.api.nvim_set_current_buf(buf)

    assert.is_false(memory_store.has_anchors())
    
    memory_store.add_anchor(10, 1)
    assert.is_true(memory_store.has_anchors())
    
    memory_store.clear_anchors()
    assert.is_false(memory_store.has_anchors())
  end)

  it("should get buffers with anchors", function()
    local buf1 = create_fake_buffer("buffers_test1")
    local buf2 = create_fake_buffer("buffers_test2")
    local buf3 = create_fake_buffer("buffers_test3")

    vim.api.nvim_set_current_buf(buf1)
    memory_store.add_anchor(10, 1)
    
    vim.api.nvim_set_current_buf(buf3)
    memory_store.add_anchor(30, 3)

    local buffers_with_anchors = memory_store.get_buffers_with_anchors()
    assert.equals(2, #buffers_with_anchors)
    
    -- Should contain buf1 and buf3, but not buf2
    local contains_buf1 = false
    local contains_buf3 = false
    for _, bufnr in ipairs(buffers_with_anchors) do
      if bufnr == buf1 then contains_buf1 = true end
      if bufnr == buf3 then contains_buf3 = true end
    end
    assert.is_true(contains_buf1)
    assert.is_true(contains_buf3)
  end)
end)

