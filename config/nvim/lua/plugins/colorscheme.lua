return {
    {
        "catppuccin/nvim",
        name = "catppuccin",
        priority = 1000, -- Load before all other plugins
        opts = {
            flavour = "mocha",
            integrations = {
                treesitter = true,
                telescope = { enabled = true },
                nvimtree = true,
                lualine = true,
                mason = true,
                which_key = true,
                gitsigns = true,
                cmp = true,
                trouble = true,
            },
        },
        config = function(_, opts)
            require("catppuccin").setup(opts)
            vim.cmd.colorscheme("catppuccin")
        end,
    },
}
