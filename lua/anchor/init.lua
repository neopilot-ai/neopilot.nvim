-- lua/anchor/init.lua: Entry point that sets up commands.

local M = {}

-- Default configuration
local default_config = {
  -- Key mappings
  mappings = {
    add = "<leader>aa",
    jump = "<leader>aj",
    list = "<leader>al",
    clear = "<leader>ac",
    ui = "<leader>au",
    telescope = "<leader>at",
  },
  -- UI settings
  ui = {
    border = "rounded",
    width_ratio = 0.8,
    height_ratio = 0.6,
  },
  -- Visual indicators
  signs = {
    enabled = true,
    text = "⚓",
    hl_group = "DiagnosticSignInfo",
  },
  -- Anchor limits
  max_anchors_per_buffer = 50,
  -- Auto cleanup
  auto_cleanup = true,
}

local config = default_config

function M.setup(opts)
  -- Merge user config with defaults
  config = vim.tbl_deep_extend("force", default_config, opts or {})

  -- Create user commands
  vim.api.nvim_create_user_command(
    "AnchorAdd",
    function()
      require("anchor.memory_store").add_anchor(vim.api.nvim_win_get_cursor(0)[1], vim.api.nvim_win_get_cursor(0)[2])
    end,
    {
      desc = "Add an anchor at cursor position",
    }
  )

  vim.api.nvim_create_user_command("AnchorJump", function(args)
    local index = tonumber(args.args)
    if index then
      require("anchor.memory_store").jump_to_anchor(index)
    else
      print("Please provide a valid index.")
    end
  end, {
    nargs = 1,
    desc = "Jump to nth anchor",
  })

  vim.api.nvim_create_user_command("AnchorList", function() require("anchor.memory_store").list_anchors() end, {
    desc = "List all anchors in current buffer",
  })

  vim.api.nvim_create_user_command("AnchorClear", function() require("anchor.memory_store").clear_anchors() end, {
    desc = "Clear all anchors in current buffer",
  })

  vim.api.nvim_create_user_command("AnchorRemove", function(args)
    if args.args == "" then
      print("Usage: AnchorRemove <label>")
      return
    end
    require("anchor.list").remove(args.args)
  end, {
    nargs = 1,
    desc = "Remove a specific anchor by label",
  })

  vim.api.nvim_create_user_command("AnchorUI", function() require("anchor.ui").show_current() end, {
    desc = "Show anchors in floating UI",
  })

  vim.api.nvim_create_user_command("AnchorUIAll", function() require("anchor.ui").show_all() end, {
    desc = "Show all anchors from all buffers in floating UI",
  })

  vim.api.nvim_create_user_command("AnchorTelescope", function() require("anchor.telescope").current_buffer() end, {
    desc = "Show anchors in Telescope picker",
  })

  vim.api.nvim_create_user_command("AnchorTelescopeAll", function() require("anchor.telescope").all_buffers() end, {
    desc = "Show all anchors from all buffers in Telescope picker",
  })

  -- Set up buffer cleanup autocmd
  vim.api.nvim_create_autocmd("BufDelete", {
    group = vim.api.nvim_create_augroup("AnchorCleanup", { clear = true }),
    callback = function(args) require("anchor.memory_store").cleanup_buffer(args.buf) end,
  })

  -- Set up key mappings if provided
  if config.mappings then
    local mappings = config.mappings

    if mappings.add then
      vim.keymap.set("n", mappings.add, function() M.add() end, { desc = "Add anchor", silent = true })
    end

    if mappings.jump then
      vim.keymap.set("n", mappings.jump, function()
        -- Interactive jump - let user select from list
        require("anchor.memory_store").list_anchors()
      end, { desc = "Jump to anchor", silent = true })
    end

    if mappings.list then
      vim.keymap.set(
        "n",
        mappings.list,
        function() require("anchor.memory_store").list_anchors() end,
        { desc = "List anchors", silent = true }
      )
    end

    if mappings.clear then
      vim.keymap.set(
        "n",
        mappings.clear,
        function() require("anchor.memory_store").clear_anchors() end,
        { desc = "Clear anchors", silent = true }
      )
    end

    if mappings.ui then
      vim.keymap.set(
        "n",
        mappings.ui,
        function() require("anchor.ui").show_current() end,
        { desc = "Show anchor UI", silent = true }
      )
    end

    if mappings.telescope then
      vim.keymap.set(
        "n",
        mappings.telescope,
        function() require("anchor.telescope").current_buffer() end,
        { desc = "Show anchors in Telescope", silent = true }
      )
    end
  end
end

-- Get current configuration
function M.get_config() return config end

function M.add()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  require("anchor.memory_store").add_anchor(row, col)
end

function M.jump(index) require("anchor.memory_store").jump_to_anchor(index) end

return M
