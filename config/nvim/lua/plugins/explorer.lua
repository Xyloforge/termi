return {
    {
        "nvim-tree/nvim-tree.lua",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            -- Disable netrw (nvim-tree replacement)
            vim.g.loaded_netrw = 1
            vim.g.loaded_netrwPlugin = 1

            require("nvim-tree").setup({
                view = { width = 35, side = "left" },
                renderer = {
                    group_empty = true,
                    icons = { show = { git = true, file = true, folder = true } },
                },
                filters = { dotfiles = false },
                git = { enable = true, ignore = false },
                actions = {
                    open_file = { quit_on_open = false },
                },
            })

            local map = vim.keymap.set
            map("n", "<leader>ee", "<cmd>NvimTreeToggle<CR>",   { desc = "Toggle file tree" })
            map("n", "<leader>ef", "<cmd>NvimTreeFindFile<CR>", { desc = "Find file in tree" })
            map("n", "<leader>ec", "<cmd>NvimTreeCollapse<CR>", { desc = "Collapse tree" })
            map("n", "<leader>eo", "<cmd>NvimTreeFocus<CR>",    { desc = "Focus file tree" })
        end,
    },
}
