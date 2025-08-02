return {
  "stevearc/conform.nvim",
  opts = {
    formatters_by_ft = {
      lua = { "stylua" },
      go = { "gofmt" },
      javascript = { "prettier" },
      typescript = { "prettier" },
      elixir = { "mix" }
    }
  },
  config = function(_, opts)
    require("conform").setup(opts)
  end,
}
