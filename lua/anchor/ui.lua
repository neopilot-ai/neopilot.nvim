-- lua/anchor/ui.lua: Enhanced floating UI for listing anchors with improved features.

local M = {}

-- Configuration
local config = {
  border = "rounded",
  width_ratio = 0.8,
  height_ratio = 0.6,
  min_width = 60,
  min_height = 15,
  max_line_length = 80,
  show_line_numbers = true,
  highlights = {
    title = "FloatTitle",
    border = "FloatBorder",
    normal = "NormalFloat",
    cursor_line = "CursorLine",
    header = "Comment",
    index = "Number",
    filename = "Directory",
    line_number = "LineNr",
    content = "Normal",
  },
}

-- Setup function to allow configuration
function M.setup(opts) config = vim.tbl_deep_extend("force", config, opts or {}) end

-- Create a floating window with enhanced styling
local function create_floating_window(title, anchor_count)
  local width = math.floor(vim.o.columns * config.width_ratio)
  local height = math.floor(vim.o.lines * config.height_ratio)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  -- Ensure minimum size
  width = math.max(width, config.min_width)
  height = math.max(height, config.min_height)

  -- Adjust height based on content if needed
  local content_height = anchor_count + 4 -- headers + padding
  if content_height < height then
    height = math.max(content_height, config.min_height)
    row = math.floor((vim.o.lines - height) / 2)
  end

  -- Create buffer
  local buf = vim.api.nvim_create_buf(false, true)

  -- Set buffer options
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
  vim.api.nvim_set_option_value("filetype", "anchor-list", { buf = buf })
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
  vim.api.nvim_set_option_value("readonly", true, { buf = buf })
  vim.api.nvim_set_option_value("cursorline", true, { buf = buf })

  -- Enhanced title with count
  local full_title = title or " Anchors "
  if anchor_count and anchor_count > 0 then full_title = string.format(" Anchors (%d) ", anchor_count) end

  -- Create window with enhanced styling
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = config.border,
    title = full_title,
    title_pos = "center",
  })

  -- Set window-specific options
  vim.api.nvim_set_option_value("wrap", false, { win = win })
  vim.api.nvim_set_option_value("cursorline", true, { win = win })

  return buf, win
end

-- Apply syntax highlighting to the buffer
local function apply_highlights(buf, lines)
  -- Create namespace for highlights
  local ns_id = vim.api.nvim_create_namespace("anchor_ui_highlights")

  -- Clear existing highlights
  vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)

  for line_num, line_content in ipairs(lines) do
    -- Header highlight
    if line_num == 1 then
      vim.api.nvim_buf_add_highlight(buf, ns_id, config.highlights.header, line_num - 1, 0, -1)
    -- Anchor entry highlights
    elseif line_content:match("^%s*%d+%.") then
      -- Highlight the index number
      local index_end = line_content:find("%.")
      if index_end then
        vim.api.nvim_buf_add_highlight(buf, ns_id, config.highlights.index, line_num - 1, 0, index_end)
      end

      -- Highlight filename or line number
      local filename_match = line_content:match("(%S+):(%d+)")
      local line_match = line_content:match("Line (%d+)")

      if filename_match then
        local start_pos = line_content:find(filename_match)
        local end_pos = start_pos + #filename_match - 1
        vim.api.nvim_buf_add_highlight(buf, ns_id, config.highlights.filename, line_num - 1, start_pos - 1, end_pos)
      elseif line_match then
        local start_pos = line_content:find("Line " .. line_match)
        local end_pos = start_pos + #("Line " .. line_match) - 1
        vim.api.nvim_buf_add_highlight(buf, ns_id, config.highlights.line_number, line_num - 1, start_pos - 1, end_pos)
      end
    end
  end
end

-- Enhanced function to format and display anchor information
local function format_anchor_line(anchor, index, show_all_buffers)
  local line_text = ""
  local display_text = ""

  if show_all_buffers then
    -- For all buffers view
    local bufname = vim.api.nvim_buf_get_name(anchor.bufnr)
    local filename = vim.fn.fnamemodify(bufname, ":t")

    -- Safely get line text if buffer is still valid
    if vim.api.nvim_buf_is_valid(anchor.bufnr) then
      local ok, text = pcall(vim.api.nvim_buf_get_lines, anchor.bufnr, anchor.row - 1, anchor.row, false)
      if ok and text[1] then
        line_text = text[1]:gsub("^%s+", ""):sub(1, config.max_line_length) -- Trim and truncate
      end
    end

    -- Add label if available
    local label_part = anchor.label and (" [" .. anchor.label .. "]") or ""
    display_text = string.format("%2d. %s:%d%s - %s", index, filename, anchor.row, label_part, line_text)
  else
    -- For current buffer view
    line_text = vim.fn.getline(anchor.row)
    if line_text then
      line_text = line_text:gsub("^%s+", ""):sub(1, config.max_line_length) -- Trim and truncate
    end

    -- Add label if available
    local label_part = anchor.label and (" [" .. anchor.label .. "]") or ""
    display_text = string.format("%2d. Line %d%s - %s", index, anchor.row, label_part, line_text)
  end

  return display_text
end

-- Show anchors in a floating window using the memory store
local function show_anchors_floating(anchors, show_all_buffers)
  local buf, win = create_floating_window(" Anchors ", #anchors)
  local lines = {}
  local anchor_map = {}

  -- Enhanced header with keyboard shortcuts
  table.insert(lines, "📍 Navigate: j/k ↕   Select: CR   Quit: q/Esc   Delete: d")
  table.insert(lines, string.rep("─", 60))

  -- Add anchors to display with enhanced formatting
  for i, anchor in ipairs(anchors) do
    local display_text = format_anchor_line(anchor, i, show_all_buffers)
    table.insert(lines, display_text)
    anchor_map[#lines] = anchor -- Map line number to anchor
  end

  -- Add footer if many anchors
  if #anchors > 10 then
    table.insert(lines, "")
    table.insert(lines, string.format("📊 Total: %d anchors", #anchors))
  end

  -- Set buffer content
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  -- Apply syntax highlighting
  apply_highlights(buf, lines)

  -- Set cursor to first anchor line
  if #anchors > 0 then
    vim.api.nvim_win_set_cursor(win, { 3, 0 }) -- Skip header lines
  end

  -- Helper functions
  local function close_window()
    if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
  end

  local function jump_to_anchor()
    local cursor_line = vim.api.nvim_win_get_cursor(win)[1]
    local anchor = anchor_map[cursor_line]

    if anchor then
      close_window()

      -- Switch to the buffer if it's different and valid
      if
        show_all_buffers
        and vim.api.nvim_buf_is_valid(anchor.bufnr)
        and anchor.bufnr ~= vim.api.nvim_get_current_buf()
      then
        vim.api.nvim_set_current_buf(anchor.bufnr)
      end

      -- Jump to position
      vim.api.nvim_win_set_cursor(0, { anchor.row, anchor.col })

      -- Center the view
      vim.cmd("normal! zz")

      -- Enhanced feedback message
      local label_info = anchor.label and (" (" .. anchor.label .. ")") or ""
      print(string.format("📍 Jumped to line %d%s", anchor.row, label_info))
    end
  end

  local function delete_anchor()
    local cursor_line = vim.api.nvim_win_get_cursor(win)[1]
    local anchor = anchor_map[cursor_line]

    if anchor then
      -- Find the anchor index in the memory store
      local memory_store = require("anchor.memory_store")
      local current_anchors = show_all_buffers and memory_store.get_all_anchors() or memory_store.get_anchors()

      for idx, stored_anchor in ipairs(current_anchors) do
        if
          stored_anchor.row == anchor.row
          and stored_anchor.col == anchor.col
          and (not show_all_buffers or stored_anchor.bufnr == anchor.bufnr)
        then
          memory_store.remove_anchor(idx, show_all_buffers and anchor.bufnr or nil)
          close_window()

          -- Show updated list if there are still anchors
          local updated_anchors = show_all_buffers and memory_store.get_all_anchors() or memory_store.get_anchors()
          if #updated_anchors > 0 then
            vim.defer_fn(function() show_anchors_floating(updated_anchors, show_all_buffers) end, 50)
          else
            print("🗑️  All anchors deleted")
          end
          return
        end
      end
    end
  end

  local function move_cursor_safe(direction)
    local current_line = vim.api.nvim_win_get_cursor(win)[1]
    local new_line = current_line + direction
    local total_lines = vim.api.nvim_buf_line_count(buf)

    -- Keep cursor within anchor lines (skip header and footer)
    if new_line < 3 then
      new_line = 3
    elseif new_line > #anchors + 2 then
      new_line = #anchors + 2
    end

    vim.api.nvim_win_set_cursor(win, { new_line, 0 })
  end

  -- Set enhanced keymaps for the buffer
  local opts = { buffer = buf, nowait = true, silent = true }

  -- Close window
  vim.keymap.set("n", "q", close_window, opts)
  vim.keymap.set("n", "Esc", close_window, opts)

  -- Jump to anchor
  vim.keymap.set("n", "CR", jump_to_anchor, opts)
  vim.keymap.set("n", "2-LeftMouse", jump_to_anchor, opts)
  vim.keymap.set("n", "Space", jump_to_anchor, opts)

  -- Delete anchor
  vim.keymap.set("n", "d", delete_anchor, opts)
  vim.keymap.set("n", "x", delete_anchor, opts)

  -- Enhanced navigation
  vim.keymap.set("n", "j", function() move_cursor_safe(1) end, opts)
  vim.keymap.set("n", "k", function() move_cursor_safe(-1) end, opts)
  vim.keymap.set("n", "Down", function() move_cursor_safe(1) end, opts)
  vim.keymap.set("n", "Up", function() move_cursor_safe(-1) end, opts)

  -- Quick navigation
  vim.keymap.set("n", "gg", function() vim.api.nvim_win_set_cursor(win, { 3, 0 }) end, opts)
  vim.keymap.set("n", "G", function() vim.api.nvim_win_set_cursor(win, { #anchors + 2, 0 }) end, opts)

  -- Help
  vim.keymap.set(
    "n",
    "?",
    function()
      vim.notify(
        [[
🔗 Anchor UI Help:

Navigation:
  j/k or ↑/↓  - Move up/down
  gg/G        - Go to first/last anchor
  
Actions:
  CR or Space - Jump to anchor
  d or x          - Delete anchor
  q or Esc      - Close window
  ?               - Show this help
    ]],
        vim.log.levels.INFO,
        { title = "Anchor UI" }
      )
    end,
    opts
  )

  -- Auto-close on focus lost
  vim.api.nvim_create_autocmd("WinLeave", {
    buffer = buf,
    once = true,
    callback = close_window,
  })

  -- Status line
  vim.api.nvim_set_option_value(
    "statusline",
    string.format("%%#StatusLine# Anchors (%d) | CR=Jump d=Delete q=Quit %%*", #anchors),
    { win = win }
  )
end

-- Public functions

-- List anchors using floating UI for the current buffer
function M.show_current_floating()
  local anchors = require("anchor.memory_store").get_anchors()
  if #anchors == 0 then
    vim.notify("📍 No anchors found in current buffer", vim.log.levels.INFO)
    return
  end
  show_anchors_floating(anchors, false)
end

-- List anchors from all buffers using floating UI
function M.show_all_floating()
  local all_anchors = require("anchor.memory_store").get_all_anchors()
  if #all_anchors == 0 then
    vim.notify("📍 No anchors found in any buffer", vim.log.levels.INFO)
    return
  end
  show_anchors_floating(all_anchors, true)
end

-- Show anchors for current buffer only
function M.show_current() M.show_current_floating() end

-- Show anchors for all buffers
function M.show_all() M.show_all_floating() end

-- Get current configuration
function M.get_config() return config end

-- Preview anchor without jumping (for telescope-like experience)
function M.preview_anchor(anchor, show_all_buffers)
  if show_all_buffers and vim.api.nvim_buf_is_valid(anchor.bufnr) then
    -- Create a preview window for cross-buffer anchors
    local preview_buf = vim.api.nvim_create_buf(false, true)
    local bufname = vim.api.nvim_buf_get_name(anchor.bufnr)
    local filename = vim.fn.fnamemodify(bufname, ":t")

    -- Get context lines around the anchor
    local context_lines = 5
    local start_line = math.max(1, anchor.row - context_lines)
    local end_line = anchor.row + context_lines

    local ok, lines = pcall(vim.api.nvim_buf_get_lines, anchor.bufnr, start_line - 1, end_line, false)
    if ok and lines then
      local preview_lines = { string.format("Preview: %s:%d", filename, anchor.row), "" }
      for i, line in ipairs(lines) do
        local line_num = start_line + i - 1
        local prefix = (line_num == anchor.row) and "" or "   "
        table.insert(preview_lines, string.format("%s %3d: %s", prefix, line_num, line))
      end

      vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, preview_lines)
      -- Could show this in a split or popup
    end
  end
end

return M
