return {
    -- Status line
    {
        "nvim-lualine/lualine.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        opts = {
            options = {
                theme = "catppuccin",
                globalstatus = true,
                component_separators = "|",
                section_separators = { left = "", right = "" },
            },
            sections = {
                lualine_a = { "mode" },
                lualine_b = { "branch", "diff", "diagnostics" },
                lualine_c = { { "filename", path = 1 } },
                lualine_x = { "encoding", "fileformat", "filetype" },
                lualine_y = { "progress" },
                lualine_z = { "location" },
            },
        },
    },

    -- Keybinding popup
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        opts = {
            win = { border = "rounded" },
        },
        config = function(_, opts)
            local wk = require("which-key")
            wk.setup(opts)
            -- Register group prefixes
            wk.add({
                { "<leader>f", group = "Find (Telescope)" },
                { "<leader>g", group = "Git" },
                { "<leader>h", group = "Hunks" },
                { "<leader>e", group = "Explorer" },
                { "<leader>s", group = "Splits" },
                { "<leader>b", group = "Buffer" },
            })
        end,
    },

    -- Diagnostics / quickfix list
    {
        "folke/trouble.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        opts = { use_diagnostic_signs = true },
        keys = {
            { "<leader>xx", "<cmd>TroubleToggle<CR>",                       desc = "Trouble toggle" },
            { "<leader>xw", "<cmd>TroubleToggle workspace_diagnostics<CR>", desc = "Workspace diagnostics" },
            { "<leader>xd", "<cmd>TroubleToggle document_diagnostics<CR>",  desc = "Document diagnostics" },
            { "<leader>xq", "<cmd>TroubleToggle quickfix<CR>",              desc = "Quickfix list" },
        },
    },
}
