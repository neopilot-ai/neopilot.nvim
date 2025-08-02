-- Root files to identify project root
local root_files = {
  '.luarc.json', '.luarc.jsonc', '.luacheckrc',
  '.stylua.toml', 'stylua.toml', 'selene.toml',
  'selene.yml', '.git',
}

-- Set up LSP capabilities with nvim-cmp support
local function get_capabilities()
  local cmp_lsp = require("cmp_nvim_lsp")
  return vim.tbl_deep_extend(
    "force",
    {},
    vim.lsp.protocol.make_client_capabilities(),
    cmp_lsp.default_capabilities()
  )
end

-- Set up LSP servers with handlers
local function setup_lsp_servers(capabilities)
  require("mason-lspconfig").setup({
    ensure_installed = { "lua_ls", "rust_analyzer", "gopls" },
    handlers = {
      -- Default handler for most servers
      function(server_name)
        require("lspconfig")[server_name].setup { capabilities = capabilities }
      end,

      -- Zig LSP custom setup
      zls = function()
        local lspconfig = require("lspconfig")
        lspconfig.zls.setup({
          capabilities = capabilities,
          root_dir = lspconfig.util.root_pattern(".git", "build.zig", "zls.json"),
          settings = {
            zls = {
              enable_inlay_hints = true,
              enable_snippets = true,
              warn_style = true,
            },
          },
        })
        vim.g.zig_fmt_parse_errors = 0
        vim.g.zig_fmt_autosave = 0
      end,

      -- Lua LSP custom setup
      ["lua_ls"] = function()
        local lspconfig = require("lspconfig")
        lspconfig.lua_ls.setup {
          capabilities = capabilities,
          root_dir = lspconfig.util.root_pattern(unpack(root_files)),
          settings = {
            Lua = {
              format = {
                enable = true,
                defaultConfig = {
                  indent_style = "space",
                  indent_size = "2",
                }
              },
            }
          }
        }
      end,
    }
  })
end

-- Set up nvim-cmp completion
local function setup_cmp()
  local cmp = require('cmp')
  local cmp_select = { behavior = cmp.SelectBehavior.Select }
  cmp.setup({
    snippet = {
      expand = function(args)
        require('luasnip').lsp_expand(args.body)
      end,
    },
    mapping = cmp.mapping.preset.insert({
      ['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
      ['<C-n>'] = cmp.mapping.select_next_item(cmp_select),
      ['<C-y>'] = cmp.mapping.confirm({ select = true }),
      ["<C-Space>"] = cmp.mapping.complete(),
    }),
    sources = cmp.config.sources({
      { name = "copilot", group_index = 2 },
      { name = 'nvim_lsp' },
      { name = 'luasnip' },
    }, {
      { name = 'buffer' },
    })
  })
end

-- Set up diagnostics UI
local function setup_diagnostics()
  vim.diagnostic.config({
    float = {
      focusable = false,
      style = "minimal",
      border = "rounded",
      source = "always",
      header = "",
      prefix = "",
    },
  })
end

return {
  "neovim/nvim-lspconfig",
  dependencies = {
    "stevearc/conform.nvim",
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
    "hrsh7th/cmp-nvim-lsp",
    "hrsh7th/cmp-buffer",
    "hrsh7th/cmp-path",
    "hrsh7th/cmp-cmdline",
    "hrsh7th/nvim-cmp",
    "L3MON4D3/LuaSnip",
    "saadparwaiz1/cmp_luasnip",
    "j-hui/fidget.nvim",
  },

  config = function()
    require("conform").setup({ formatters_by_ft = {} })
    require("fidget").setup({})
    require("mason").setup()

    local capabilities = get_capabilities()
    setup_lsp_servers(capabilities)
    setup_cmp()
    setup_diagnostics()

    -- LSP keymaps (on attach)
    vim.api.nvim_create_autocmd('LspAttach', {
      callback = function(args)
        local bufnr = args.buf
        local opts = { buffer = bufnr }
        local map = vim.keymap.set
        map('n', 'gd', vim.lsp.buf.definition, opts)
        map('n', 'gD', vim.lsp.buf.declaration, opts)
        map('n', 'K', vim.lsp.buf.hover, opts)
        map('n', 'gi', vim.lsp.buf.implementation, opts)
        map('n', '<leader>rn', vim.lsp.buf.rename, opts)
        map('n', '<leader>ca', vim.lsp.buf.code_action, opts)
        map('n', '[d', vim.diagnostic.goto_prev, opts)
        map('n', ']d', vim.diagnostic.goto_next, opts)
        map('n', '<leader>e', vim.diagnostic.open_float, opts)
      end
    })

    -- Snippet choice keymap
    vim.keymap.set({ "i", "s" }, "<C-j>", function()
      require("luasnip").jump(1)
    end, { silent = true, desc = "Jump to next snippet placeholder" })
  end
}
