-- lua/khulnasoft/plugins/treesitter.lua

-- Guard against missing nvim-treesitter
local ok, ts_config = pcall(require, "nvim-treesitter.configs")
if not ok then
  vim.notify("nvim-treesitter.configs not found!", vim.log.levels.WARN)
  return
end

ts_config.setup({
  -- Language parsers to install
  ensure_installed = {
    "lua", "bash", "python", "go", "rust", "javascript",
    "html", "json", "yaml", "css", "markdown"
  },

  -- Syntax highlighting
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
  },

  -- Indentation
  indent = {
    enable = true,
  },

  -- Incremental selection
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection    = "<C-space>",
      node_incremental  = "<C-space>", -- Consider using <C-s> or another key to avoid overlap
      scope_incremental = "<C-s>",
      node_decremental  = "<BS>",
    },
  },

  -- Textobjects for functions/classes, movement, etc.
  textobjects = {
    select = {
      enable = true,
      lookahead = true,
      keymaps = {
        ["af"] = "@function.outer",
        ["if"] = "@function.inner",
        ["ac"] = "@class.outer",
        ["ic"] = "@class.inner",
      },
    },
    move = {
      enable = true,
      set_jumps = true, -- Set jumps in the jumplist
      goto_next_start = {
        ["]f"] = "@function.outer",
        ["]c"] = "@class.outer",
      },
      goto_previous_start = {
        ["[f"] = "@function.outer",
        ["[c"] = "@class.outer",
      },
    },
  },

  -- Refactor tools
  refactor = {
    highlight_definitions = {
      enable = true,
      clear_on_cursor_move = true, -- Optional: Avoid lingering highlights
    },
    smart_rename = {
      enable = false,
    },
    navigation = {
      enable = true,
      keymaps = {
        goto_definition = "gnd",
        list_definitions = "gnD",
        goto_next_usage = "<A-*>",
        goto_previous_usage = "<A-#>",
      },
    },
  },

  -- Treesitter playground for debugging/learning Treesitter queries
  playground = {
    enable = true,
    updatetime = 25,
    persist_queries = false,
  },

  -- Treesitter folding
  fold = {
    enable = true,
  },
})

-- Set up Vim folding using Treesitter
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
vim.opt.foldlevel = 99 -- Open all folds by default
