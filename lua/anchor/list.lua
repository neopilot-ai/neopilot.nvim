-- lua/anchor/list.lua: Manages anchor data per buffer.

local M = {}

-- Namespace for extmarks
local namespace = vim.api.nvim_create_namespace("anchor_marks")

-- Table to store anchor metadata per buffer: { [bufnr] = { [mark_id] = {label, timestamp}, ... } }
local anchors = {}

-- Table to store label to mark_id mapping per buffer for quick lookups
local label_to_mark = {}

-- Get the current buffer number
local function get_current_buffer() return vim.api.nvim_get_current_buf() end

-- Helper function to get current position of an extmark
local function get_mark_position(bufnr, mark_id)
  local mark = vim.api.nvim_buf_get_extmark_by_id(bufnr, namespace, mark_id, {})
  if mark and #mark >= 2 then
    return mark[1] + 1, mark[2] -- Convert to 1-based line numbering
  end
  return nil, nil
end

-- Helper function to check if a mark still exists
local function mark_exists(bufnr, mark_id)
  local success, _ = pcall(vim.api.nvim_buf_get_extmark_by_id, bufnr, namespace, mark_id, {})
  return success
end

-- Get anchors for a specific buffer (returns current positions from extmarks)
function M.get_anchors(bufnr)
  bufnr = bufnr or get_current_buffer()
  local buffer_anchors = anchors[bufnr] or {}
  local result = {}

  -- Convert extmark data to anchor format with current positions
  for mark_id, anchor_data in pairs(buffer_anchors) do
    if mark_exists(bufnr, mark_id) then
      local line, col = get_mark_position(bufnr, mark_id)
      if line and col then
        table.insert(result, {
          line = line,
          col = col,
          label = anchor_data.label,
          timestamp = anchor_data.timestamp,
          mark_id = mark_id,
        })
      end
    else
      -- Clean up stale anchor
      anchors[bufnr][mark_id] = nil
      if label_to_mark[bufnr] then
        for label, mid in pairs(label_to_mark[bufnr]) do
          if mid == mark_id then
            label_to_mark[bufnr][label] = nil
            break
          end
        end
      end
    end
  end

  -- Sort by line number
  table.sort(result, function(a, b) return a.line < b.line end)

  return result
end

-- Add an anchor at the current cursor position
function M.add(label)
  local bufnr = get_current_buffer()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = cursor[1] - 1 -- Convert to 0-based for extmark
  local col = cursor[2]

  -- If no label provided, prompt for one
  if not label then
    label = vim.fn.input("Anchor label: ")
    if label == "" then
      print("Anchor not added: empty label")
      return
    end
  end

  -- Validate label
  if type(label) ~= "string" or label:match("^%s*$") then
    print("Error: Label must be a non-empty string")
    return
  end

  -- Initialize tables for this buffer if they don't exist
  if not anchors[bufnr] then anchors[bufnr] = {} end
  if not label_to_mark[bufnr] then label_to_mark[bufnr] = {} end

  -- Check if anchor with this label already exists
  local existing_mark_id = label_to_mark[bufnr][label]
  if existing_mark_id and mark_exists(bufnr, existing_mark_id) then
    -- Move existing extmark to new position
    vim.api.nvim_buf_set_extmark(bufnr, namespace, line, col, {
      id = existing_mark_id,
    })
    anchors[bufnr][existing_mark_id].timestamp = os.time()
    print("Updated anchor '" .. label .. "' at line " .. (line + 1))
    return
  elseif existing_mark_id then
    -- Clean up stale reference
    anchors[bufnr][existing_mark_id] = nil
    label_to_mark[bufnr][label] = nil
  end

  -- Create new extmark
  local mark_id = vim.api.nvim_buf_set_extmark(bufnr, namespace, line, col, {
    sign_text = "⚓",
    sign_hl_group = "DiagnosticSignInfo",
  })

  -- Store anchor metadata
  anchors[bufnr][mark_id] = {
    label = label,
    timestamp = os.time(),
  }
  label_to_mark[bufnr][label] = mark_id

  print("Added anchor '" .. label .. "' at line " .. (line + 1))
end

-- Jump to an anchor
function M.jump(label)
  local bufnr = get_current_buffer()
  local buffer_anchors = M.get_anchors(bufnr)

  if #buffer_anchors == 0 then
    print("No anchors found in current buffer")
    return
  end

  -- If no label provided, show all anchors and let user choose
  if not label then
    if #buffer_anchors == 1 then
      -- Jump to the only anchor
      local anchor = buffer_anchors[1]
      vim.api.nvim_win_set_cursor(0, { anchor.line, anchor.col })
      print("Jumped to anchor '" .. anchor.label .. "'")
      return
    else
      -- Show selection menu
      local labels = {}
      for i, anchor in ipairs(buffer_anchors) do
        table.insert(labels, string.format("%d. %s (line %d)", i, anchor.label, anchor.line))
      end

      local choice = vim.fn.inputlist(vim.list_extend({ "Select anchor:" }, labels))
      if choice > 0 and choice <= #buffer_anchors then
        local anchor = buffer_anchors[choice]
        vim.api.nvim_win_set_cursor(0, { anchor.line, anchor.col })
        print("Jumped to anchor '" .. anchor.label .. "'")
      end
      return
    end
  end

  -- Jump to specific label
  for _, anchor in ipairs(buffer_anchors) do
    if anchor.label == label then
      vim.api.nvim_win_set_cursor(0, { anchor.line, anchor.col })
      print("Jumped to anchor '" .. label .. "'")
      return
    end
  end

  print("Anchor '" .. label .. "' not found")
end

-- Clear anchors
function M.clear(bufnr)
  bufnr = bufnr or get_current_buffer()

  if not anchors[bufnr] then
    print("No anchors to clear in current buffer")
    return
  end

  local count = 0
  -- Delete all extmarks for this buffer
  for mark_id, _ in pairs(anchors[bufnr]) do
    if mark_exists(bufnr, mark_id) then
      vim.api.nvim_buf_del_extmark(bufnr, namespace, mark_id)
      count = count + 1
    end
  end

  -- Clear metadata
  anchors[bufnr] = nil
  label_to_mark[bufnr] = nil

  print("Cleared " .. count .. " anchor(s) from buffer")
end

-- List all anchors in current buffer
function M.list()
  local bufnr = get_current_buffer()
  local buffer_anchors = M.get_anchors(bufnr)

  if #buffer_anchors == 0 then
    print("No anchors found in current buffer")
    return
  end

  print("Anchors in current buffer:")
  for i, anchor in ipairs(buffer_anchors) do
    print(string.format("  %d. %s (line %d, col %d)", i, anchor.label, anchor.line, anchor.col))
  end
end

-- Remove a specific anchor by label
function M.remove(label)
  local bufnr = get_current_buffer()

  if not label then
    print("Please specify anchor label to remove")
    return
  end

  if not anchors[bufnr] or not label_to_mark[bufnr] then
    print("Anchor '" .. label .. "' not found")
    return
  end

  local mark_id = label_to_mark[bufnr][label]
  if not mark_id then
    print("Anchor '" .. label .. "' not found")
    return
  end

  -- Delete the extmark
  if mark_exists(bufnr, mark_id) then vim.api.nvim_buf_del_extmark(bufnr, namespace, mark_id) end

  -- Clean up metadata
  anchors[bufnr][mark_id] = nil
  label_to_mark[bufnr][label] = nil

  print("Removed anchor '" .. label .. "'")
end

-- Get all anchors across all buffers (for telescope integration)
function M.get_all_anchors()
  local all_anchors = {}

  for bufnr, _ in pairs(anchors) do
    local buffer_anchors = M.get_anchors(bufnr)
    local bufname = vim.api.nvim_buf_get_name(bufnr)
    local filename = vim.fn.fnamemodify(bufname, ":t") -- Get just filename

    for _, anchor in ipairs(buffer_anchors) do
      table.insert(all_anchors, {
        bufnr = bufnr,
        line = anchor.line,
        col = anchor.col,
        label = anchor.label,
        filename = filename,
        bufname = bufname,
        timestamp = anchor.timestamp,
      })
    end
  end

  return all_anchors
end

-- Clean up anchors when buffer is deleted
function M.cleanup_buffer(bufnr)
  if anchors[bufnr] then
    -- Clear all extmarks for this buffer (they should be automatically cleaned up by Neovim)
    anchors[bufnr] = nil
  end
  if label_to_mark[bufnr] then label_to_mark[bufnr] = nil end
end

return M
