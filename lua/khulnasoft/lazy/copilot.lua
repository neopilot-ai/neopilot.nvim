-- Copilot plugin configuration for Neovim
return {
    {
        "zbirenbaum/copilot.lua",
        cmd = "Copilot",
        build = ":Copilot auth",
        event = "InsertEnter",
        config = function()
            -- Protected call to handle errors gracefully
            local ok, copilot = pcall(require, "copilot")
            if not ok then
                vim.notify("Could not load Copilot!", vim.log.levels.ERROR)
                return
            end

            copilot.setup({
                panel = {
                    enabled = true,
                    auto_refresh = true,
                    keymap = {
                        jump_next = "<c-j>",   -- Next suggestion
                        jump_prev = "<c-k>",   -- Previous suggestion
                        accept = "<c-a>",      -- Accept suggestion
                        refresh = "r",         -- Refresh panel
                        open = "<M-CR>",       -- Open panel
                    },
                    layout = {
                        position = "bottom",   -- Panel position: bottom/top/left/right
                        ratio = 0.4,
                    },
                },
                suggestion = {
                    enabled = true,
                    auto_trigger = true,
                    debounce = 75,
                    keymap = {
                        accept = "<c-a>",      -- Accept suggestion
                        accept_word = false,
                        accept_line = false,
                        next = "<c-j>",        -- Next suggestion
                        prev = "<c-k>",        -- Previous suggestion
                        dismiss = "<C-e>",     -- Dismiss suggestion
                    },
                },
                -- Uncomment the following to enable debug logging
                -- debug = true,
                -- Uncomment and modify to restrict Copilot to certain filetypes
                -- filetypes = { lua = true, python = true },
            })
        end,
    },

    -- Uncomment to enable Copilot completion with nvim-cmp
    -- {
    --     "zbirenbaum/copilot-cmp",
    --     config = function()
    --         require("copilot_cmp").setup()
    --     end,
    -- }
}
