return {
    -- Gutter signs: added/changed/deleted lines
    {
        "lewis6991/gitsigns.nvim",
        event = { "BufReadPre", "BufNewFile" },
        opts = {
            signs = {
                add          = { text = "▎" },
                change       = { text = "▎" },
                delete       = { text = "" },
                topdelete    = { text = "" },
                changedelete = { text = "▎" },
            },
            on_attach = function(bufnr)
                local gs = package.loaded.gitsigns
                local map = function(keys, func, desc)
                    vim.keymap.set("n", keys, func, { buffer = bufnr, desc = "Git: " .. desc })
                end
                -- Navigation
                map("]h", gs.next_hunk,  "Next hunk")
                map("[h", gs.prev_hunk,  "Prev hunk")
                -- Actions
                map("<leader>hs", gs.stage_hunk,    "Stage hunk")
                map("<leader>hr", gs.reset_hunk,    "Reset hunk")
                map("<leader>hS", gs.stage_buffer,  "Stage buffer")
                map("<leader>hp", gs.preview_hunk,  "Preview hunk")
                map("<leader>hb", function() gs.blame_line({ full = true }) end, "Blame line")
                map("<leader>hd", gs.diffthis,      "Diff this")
            end,
        },
    },

    -- Git commands inside Neovim (classic)
    {
        "tpope/vim-fugitive",
        cmd = { "Git", "G", "Gstatus", "Gblame", "Gpush", "Gpull" },
        keys = {
            { "<leader>gg", "<cmd>Git<CR>",       desc = "Git status (fugitive)" },
            { "<leader>gp", "<cmd>Git push<CR>",  desc = "Git push" },
            { "<leader>gl", "<cmd>Git pull<CR>",  desc = "Git pull" },
        },
    },

    -- Magit-style TUI
    {
        "NeogitOrg/neogit",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "sindrets/diffview.nvim",
            "nvim-telescope/telescope.nvim",
        },
        opts = {
            integrations = { diffview = true, telescope = true },
        },
        keys = {
            { "<leader>gn", "<cmd>Neogit<CR>", desc = "Neogit" },
        },
    },
}
