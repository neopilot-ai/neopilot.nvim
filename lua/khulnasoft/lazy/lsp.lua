-- Define root files for root detection
local root_files = {
  '.luarc.json', '.luarc.jsonc', '.luacheckrc',
  '.stylua.toml', 'stylua.toml', 'selene.toml',
  'selene.yml', '.git',
}

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
    -- Uncomment if you install these:
    -- "hrsh7th/cmp-calc",
    -- "hrsh7th/cmp-nvim-lsp-signature-help",
    -- "nvimtools/none-ls.nvim" -- (null-ls replacement)
  },

  config = function()
    -- Safe require wrapper
    local function safe_require(name)
      local ok, mod = pcall(require, name)
      if ok then return mod end
      vim.notify("Failed to require: " .. name, vim.log.levels.ERROR)
      return nil
    end

    -- Setup formatters
    local conform = safe_require("conform")
    if conform then
      conform.setup({
        formatters_by_ft = {
          lua = { "stylua" },
          python = { "black" },
          go = { "gofmt" },
          javascript = { "prettier" },
          typescript = { "prettier" },
          zig = { "zigfmt" },
        }
      })
    end

    -- Setup mason (LSP/DAP installer)
    local mason = safe_require("mason")
    if mason then mason.setup() end

    local mason_lspconfig = safe_require("mason-lspconfig")
    local lspconfig = safe_require("lspconfig")
    local cmp = safe_require("cmp")
    local cmp_lsp = safe_require("cmp_nvim_lsp")

    -- LSP capabilities for completion
    local capabilities = vim.tbl_deep_extend(
      "force",
      {},
      vim.lsp.protocol.make_client_capabilities(),
      cmp_lsp and cmp_lsp.default_capabilities() or {}
    )

    -- Setup fidget (LSP status UI)
    local fidget = safe_require("fidget")
    if fidget then fidget.setup({}) end

    if mason_lspconfig then
      mason_lspconfig.setup({
        ensure_installed = {
          "lua_ls", "rust_analyzer", "tsserver", "gopls", "zls"
        },
        handlers = {
          -- Default handler
          function(server_name)
            if lspconfig then
              lspconfig[server_name].setup { capabilities = capabilities }
            end
          end,
          -- Zig (zls) special root detection
          zls = function()
            if lspconfig then
              lspconfig.zls.setup({
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
            end
          end,
          -- Lua with custom root and formatting settings
          ["lua_ls"] = function()
            if lspconfig then
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
            end
          end,
        }
      })
    end

    -- nvim-cmp setup (completion)
    if cmp then
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
          -- Uncomment if installed:
          -- { name = "nvim_lsp_signature_help" },
          -- { name = "calc" },
        }, {
          { name = 'buffer' },
        })
      })
    end

    -- Snippet choice keymap (cycle through choices)
    vim.keymap.set({ "i", "s" }, "<C-j>", function()
      local ls = safe_require("luasnip")
      if ls then ls.jump(1) end
    end, { silent = true, desc = "Jump to next snippet placeholder" })

    -- Diagnostic configuration (UI enhancements)
    vim.diagnostic.config({
      virtual_text = { spacing = 4, prefix = "●" },
      signs = true,
      underline = true,
      update_in_insert = false,
      severity_sort = true,
      float = {
        focusable = false,
        style = "minimal",
        border = "rounded",
        source = "always",
        header = "",
        prefix = "",
      },
    })

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

    -- Optional: Setup null-ls for extra formatters/linters (if installed)
    -- local null_ls = safe_require("null-ls")
    -- if null_ls then
    --   null_ls.setup({
    --     sources = {
    --       null_ls.builtins.formatting.stylua,
    --       null_ls.builtins.diagnostics.luacheck,
    --     }
    --   })
    -- end

    --[[
    Documentation:
      - All plugin setups use pcall for error safety.
      - root_files is used for Lua LSP root detection.
      - Formatters are set up for common filetypes.
      - LSP keymaps are attached on LSP attach event.
      - Diagnostics UI is enhanced for clarity.
      - Snippet cycling is mapped to <C-j>.
      - Mason LSP list is easy to extend.
      - Add more cmp sources or null-ls as desired.
    ]]
  end
}
