return {
    {
        "nvim-telescope/telescope.nvim",
        branch = "0.1.x",
        dependencies = {
            "nvim-lua/plenary.nvim",
            -- Native sorter for significantly faster performance
            {
                "nvim-telescope/telescope-fzf-native.nvim",
                build = "make",
                cond = function() return vim.fn.executable("make") == 1 end,
            },
        },
        config = function()
            local telescope = require("telescope")
            local builtin = require("telescope.builtin")

            telescope.setup({
                defaults = {
                    layout_config = { prompt_position = "top" },
                    sorting_strategy = "ascending",
                    file_ignore_patterns = { "node_modules", ".git/", "dist/" },
                    preview = { treesitter = false },
                },
            })

            if pcall(telescope.load_extension, "fzf") then
                telescope.load_extension("fzf")
            end

            -- Keymaps
            local map = vim.keymap.set
            map("n", "<leader><leader>", builtin.find_files,    { desc = "Find files" })
            map("n", "<leader>/",        builtin.live_grep,     { desc = "Live grep" })
            map("n", "<leader>fb",       builtin.buffers,       { desc = "Find buffers" })
            map("n", "<leader>fh",       builtin.help_tags,     { desc = "Find help" })
            map("n", "<leader>fr",       builtin.oldfiles,      { desc = "Recent files" })
            map("n", "<leader>fd",       builtin.diagnostics,   { desc = "Find diagnostics" })
            map("n", "<leader>fc",       builtin.commands,      { desc = "Find commands" })
            map("n", "<leader>fg",       builtin.git_status,    { desc = "Git status" })
        end,
    },
}
