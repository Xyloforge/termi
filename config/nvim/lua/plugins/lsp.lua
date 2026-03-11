return {
    -- Portable LSP/formatter/linter installer
    {
        "williamboman/mason.nvim",
        opts = { ui = { border = "rounded" } },
    },

    -- Bridge between mason and lspconfig
    {
        "williamboman/mason-lspconfig.nvim",
        dependencies = {
            "williamboman/mason.nvim",
            "neovim/nvim-lspconfig",
            "hrsh7th/cmp-nvim-lsp",
        },
        opts = {
            ensure_installed = { "lua_ls", "ts_ls", "pyright", "rust_analyzer", "bashls", "gopls" },
            automatic_installation = true,
        },
        config = function(_, opts)
            local lspconfig = require("lspconfig")
            local capabilities = require("cmp_nvim_lsp").default_capabilities()

            local on_attach = function(_, bufnr)
                local map = function(keys, func, desc)
                    vim.keymap.set("n", keys, func, { buffer = bufnr, desc = "LSP: " .. desc })
                end
                map("gd",         vim.lsp.buf.definition,      "Go to definition")
                map("gD",         vim.lsp.buf.declaration,     "Go to declaration")
                map("gr",         vim.lsp.buf.references,      "References")
                map("gi",         vim.lsp.buf.implementation,  "Go to implementation")
                map("K",          vim.lsp.buf.hover,           "Hover docs")
                map("<leader>rn", vim.lsp.buf.rename,          "Rename symbol")
                map("<leader>ca", vim.lsp.buf.code_action,     "Code action")
                map("<leader>f",  function() vim.lsp.buf.format({ async = true }) end, "Format file")
            end

            -- handlers inside setup() — required for mason-lspconfig v2+
            require("mason-lspconfig").setup({
                ensure_installed = opts.ensure_installed,
                automatic_installation = opts.automatic_installation,
                handlers = {
                    function(server)
                        lspconfig[server].setup({
                            capabilities = capabilities,
                            on_attach = on_attach,
                        })
                    end,
                    ["lua_ls"] = function()
                        lspconfig.lua_ls.setup({
                            capabilities = capabilities,
                            on_attach = on_attach,
                            settings = {
                                Lua = { diagnostics = { globals = { "vim" } } },
                            },
                        })
                    end,
                },
            })
        end,
    },

    -- LSP configs (required by mason-lspconfig)
    { "neovim/nvim-lspconfig" },
}
