-- Local plugin definitions for development and rapid iteration
local local_plugins = {
  -- The Stru (no config)
  {
    "the-stru",
    dir = "~/personal/the-stru",
  },

  -- Streamer
  {
    "streamer",
    dir = "~/personal/eleven-streamer",
    config = function()
      local streamer = require("streamer")
      local unnamed_event = require("streamer.projects.unnamed_event")
      vim.keymap.set("n", "<leader>er", streamer.reload, { desc = "Streamer: Reload" })
      vim.keymap.set("n", "<leader>es", unnamed_event.ue, { desc = "Streamer: Start unnamed event" })
      vim.keymap.set("n", "<leader>en", unnamed_event.stop, { desc = "Streamer: Stop unnamed event" })
    end,
  },

  -- Caleb (no config)
  {
    "caleb",
    dir = "~/personal/caleb",
  },

  -- Harpoon
  {
    "harpoon",
    dir = "~/personal/harpoon",
    config = function()
      local harpoon = require("harpoon")
      harpoon:setup()
      local list = harpoon:list()
      local ui = harpoon.ui

      -- Add/Prepend
      vim.keymap.set("n", "<leader>A", function() list:prepend() end, { desc = "Harpoon: Prepend" })
      vim.keymap.set("n", "<leader>a", function() list:add() end, { desc = "Harpoon: Add" })

      -- Quick menu
      vim.keymap.set("n", "<C-e>", function() ui:toggle_quick_menu(list) end, { desc = "Harpoon: Quick Menu" })

      -- Select by slot
      vim.keymap.set("n", "<C-h>", function() list:select(1) end, { desc = "Harpoon: Select 1" })
      vim.keymap.set("n", "<C-t>", function() list:select(2) end, { desc = "Harpoon: Select 2" })
      vim.keymap.set("n", "<C-n>", function() list:select(3) end, { desc = "Harpoon: Select 3" })
      vim.keymap.set("n", "<C-s>", function() list:select(4) end, { desc = "Harpoon: Select 4" })

      -- Replace at slot
      vim.keymap.set("n", "<leader><C-h>", function() list:replace_at(1) end, { desc = "Harpoon: Replace 1" })
      vim.keymap.set("n", "<leader><C-t>", function() list:replace_at(2) end, { desc = "Harpoon: Replace 2" })
      vim.keymap.set("n", "<leader><C-n>", function() list:replace_at(3) end, { desc = "Harpoon: Replace 3" })
      vim.keymap.set("n", "<leader><C-s>", function() list:replace_at(4) end, { desc = "Harpoon: Replace 4" })
    end,
  },

  -- Vim APM (example config, commented)
  {
    "vim-apm",
    dir = "~/personal/vim-apm",
    config = function()
      -- local apm = require("vim-apm")
      -- apm:setup({})
      -- vim.keymap.set("n", "<leader>apm", function() apm:toggle_monitor() end, { desc = "APM: Toggle Monitor" })
    end,
  },

  -- Vim With Me (no config)
  {
    "vim-with-me",
    dir = "~/personal/vim-with-me",
  },
}

return local_plugins
