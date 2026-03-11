return {
    -- Auto-close brackets, quotes, etc.
    {
        "windwp/nvim-autopairs",
        event = "InsertEnter",
        opts = { check_ts = true }, -- Use treesitter for smarter pairing
        config = function(_, opts)
            local autopairs = require("nvim-autopairs")
            autopairs.setup(opts)
            -- Integrate with nvim-cmp: insert `(` after selecting a function
            local cmp_autopairs = require("nvim-autopairs.completion.cmp")
            local cmp = require("cmp")
            cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
        end,
    },

    -- Surround: add/change/delete surrounding chars (ys, cs, ds)
    {
        "kylechui/nvim-surround",
        event = "VeryLazy",
        opts = {},
    },

    -- Commenting (gcc, gc in visual)
    {
        "numToStr/Comment.nvim",
        event = { "BufReadPre", "BufNewFile" },
        opts = {},
    },

    -- Indent guides
    {
        "lukas-reineke/indent-blankline.nvim",
        event = { "BufReadPost", "BufNewFile" },
        main = "ibl",
        opts = {
            indent = { char = "│" },
            scope = { enabled = true },
        },
    },

    -- Highlight word under cursor
    {
        "RRethy/vim-illuminate",
        event = { "BufReadPost", "BufNewFile" },
        config = function()
            require("illuminate").configure({
                delay = 200,
                large_file_cutoff = 2000,
            })
        end,
    },
}
