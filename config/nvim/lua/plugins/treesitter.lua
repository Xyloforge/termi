return {
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        event = { "BufReadPost", "BufNewFile" },
        opts = {
            ensure_installed = {
                "lua", "vim", "vimdoc",
                "javascript", "typescript", "tsx",
                "python", "rust", "go",
                "html", "css", "json", "yaml", "toml",
                "markdown", "markdown_inline",
                "bash", "dockerfile",
            },
            auto_install = true,
            highlight = { enable = true },
            indent = { enable = true },
        },
        main = "nvim-treesitter",
    },
}
