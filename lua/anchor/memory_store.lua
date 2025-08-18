-- lua/anchor/memory_store.lua: Simple in-memory anchor storage per buffer

local M = {}

-- Table to store anchors per buffer: { [bufnr] = { {row, col, label?}, ... } }
local anchors = {}

-- Get the current buffer number
local function get_current_buffer() return vim.api.nvim_get_current_buf() end

-- Add an anchor at the specified position
-- @param row number: 1-based line number
-- @param col number: 0-based column number
-- @param label string?: optional label for the anchor
-- @param bufnr number?: buffer number (defaults to current buffer)
-- @return number: index of the added anchor
function M.add_anchor(row, col, label, bufnr)
  bufnr = bufnr or get_current_buffer()

  -- Validate input
  if type(row) ~= "number" or row < 1 then error("Row must be a positive number") end
  if type(col) ~= "number" or col < 0 then error("Column must be a non-negative number") end

  -- Initialize anchors table for this buffer if it doesn't exist
  if not anchors[bufnr] then anchors[bufnr] = {} end

  -- Create anchor entry
  local anchor = {
    row = row,
    col = col,
    label = label,
    timestamp = os.time(),
  }

  -- Add anchor to the buffer's list
  table.insert(anchors[bufnr], anchor)

  local index = #anchors[bufnr]
  print(string.format("Added anchor %d at line %d, column %d", index, row, col))

  -- Return the index of the added anchor
  return index
end

-- Remove an anchor by index
-- @param index number: 1-based index of the anchor to remove
-- @param bufnr number?: buffer number (defaults to current buffer)
-- @return boolean: true if anchor was removed, false if index was invalid
function M.remove_anchor(index, bufnr)
  bufnr = bufnr or get_current_buffer()

  if not anchors[bufnr] then return false end

  if type(index) ~= "number" or index < 1 or index > #anchors[bufnr] then return false end

  table.remove(anchors[bufnr], index)

  -- Clean up empty buffer entries
  if #anchors[bufnr] == 0 then anchors[bufnr] = nil end

  return true
end

-- Clear all anchors for a buffer
-- @param bufnr number?: buffer number (defaults to current buffer)
-- @return number: number of anchors that were cleared
function M.clear_anchors(bufnr)
  bufnr = bufnr or get_current_buffer()

  if not anchors[bufnr] then return 0 end

  local count = #anchors[bufnr]
  anchors[bufnr] = nil

  return count
end

-- Get a list of anchors for the current buffer
-- @param bufnr number?: buffer number (defaults to current buffer)
-- @return table: array of anchor objects with row, col, label, timestamp
function M.get_anchors(bufnr)
  bufnr = bufnr or get_current_buffer()

  if not anchors[bufnr] then return {} end

  -- Return a copy to prevent external modification
  local result = {}
  for i, anchor in ipairs(anchors[bufnr]) do
    result[i] = {
      row = anchor.row,
      col = anchor.col,
      label = anchor.label,
      timestamp = anchor.timestamp,
      index = i,
    }
  end

  return result
end

-- Get anchor count for a buffer
-- @param bufnr number?: buffer number (defaults to current buffer)
-- @return number: number of anchors in the buffer
function M.get_anchor_count(bufnr)
  bufnr = bufnr or get_current_buffer()

  if not anchors[bufnr] then return 0 end

  return #anchors[bufnr]
end

-- Get a specific anchor by index
-- @param index number: 1-based index of the anchor
-- @param bufnr number?: buffer number (defaults to current buffer)
-- @return table?: anchor object or nil if not found
function M.get_anchor(index, bufnr)
  bufnr = bufnr or get_current_buffer()

  if not anchors[bufnr] or index < 1 or index > #anchors[bufnr] then return nil end

  local anchor = anchors[bufnr][index]
  return {
    row = anchor.row,
    col = anchor.col,
    label = anchor.label,
    timestamp = anchor.timestamp,
    index = index,
  }
end

-- Get all anchors across all buffers
-- @return table: array of anchor objects with bufnr included
function M.get_all_anchors()
  local result = {}

  for bufnr, buffer_anchors in pairs(anchors) do
    for i, anchor in ipairs(buffer_anchors) do
      table.insert(result, {
        bufnr = bufnr,
        row = anchor.row,
        col = anchor.col,
        label = anchor.label,
        timestamp = anchor.timestamp,
        index = i,
      })
    end
  end

  -- Sort by buffer number, then by index
  table.sort(result, function(a, b)
    if a.bufnr == b.bufnr then return a.index < b.index end
    return a.bufnr < b.bufnr
  end)

  return result
end

-- Clear all anchors from all buffers
-- @return number: total number of anchors cleared
function M.clear_all_anchors()
  local total_count = 0

  for bufnr, buffer_anchors in pairs(anchors) do
    total_count = total_count + #buffer_anchors
  end

  anchors = {}
  return total_count
end

-- Check if a buffer has any anchors
-- @param bufnr number?: buffer number (defaults to current buffer)
-- @return boolean: true if buffer has anchors
function M.has_anchors(bufnr)
  bufnr = bufnr or get_current_buffer()
  return anchors[bufnr] ~= nil and #anchors[bufnr] > 0
end

-- Get buffer numbers that have anchors
-- @return table: array of buffer numbers
function M.get_buffers_with_anchors()
  local result = {}

  for bufnr, buffer_anchors in pairs(anchors) do
    if #buffer_anchors > 0 then table.insert(result, bufnr) end
  end

  table.sort(result)
  return result
end

-- Jump to an anchor by index
-- @param index number: 1-based index of the anchor to jump to
-- @param bufnr number?: buffer number (defaults to current buffer)
-- @return boolean: true if jump was successful, false otherwise
function M.jump_to_anchor(index, bufnr)
  bufnr = bufnr or get_current_buffer()

  local anchor = M.get_anchor(index, bufnr)
  if not anchor then
    print("Anchor " .. index .. " not found")
    return false
  end

  -- Jump to the anchor position
  vim.api.nvim_win_set_cursor(0, { anchor.row, anchor.col })
  print("Jumped to anchor " .. index .. (anchor.label and (" (" .. anchor.label .. ")") or ""))

  return true
end

-- List all anchors for the current buffer (simple text output)
-- @param bufnr number?: buffer number (defaults to current buffer)
function M.list_anchors(bufnr)
  bufnr = bufnr or get_current_buffer()

  local buffer_anchors = M.get_anchors(bufnr)

  if #buffer_anchors == 0 then
    print("No anchors found in current buffer")
    return
  end

  print("Anchors in current buffer:")
  for _, anchor in ipairs(buffer_anchors) do
    local label_text = anchor.label and (" - " .. anchor.label) or ""
    print(string.format("  %d. Row %d, Col %d%s", anchor.index, anchor.row, anchor.col, label_text))
  end
end

-- Clean up anchors for deleted buffers
-- @param bufnr number: buffer number to clean up
function M.cleanup_buffer(bufnr)
  if anchors[bufnr] then anchors[bufnr] = nil end
end

return M
