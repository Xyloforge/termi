return {
    {
        "catppuccin/nvim",
        name = "catppuccin",
        priority = 1000, -- Load before all other plugins
        opts = {
            flavour = "mocha",
            -- Match VS Code void black background (#11111b) instead of default base (#1e1e2e)
            color_overrides = {
                mocha = {
                    base = "#11111b",
                    mantle = "#11111b",
                    crust = "#11111b",
                },
            },
            -- Match VS Code token colors from settings.json
            custom_highlights = function(c)
                return {
                    -- Storage keywords: var, const, func, type → red (#f38ba8)
                    ["@keyword.type"]            = { fg = c.red },
                    ["@keyword.function"]        = { fg = c.red },
                    ["@keyword.storage"]         = { fg = c.red },
                    -- Control flow: if/else/for/return → mauve bold
                    ["@keyword.return"]          = { fg = c.mauve, style = { "bold" } },
                    ["@keyword.conditional"]     = { fg = c.mauve, style = { "bold" } },
                    ["@keyword.repeat"]          = { fg = c.mauve, style = { "bold" } },
                    -- Functions → blue (#89b4fa)
                    ["@function"]                = { fg = c.blue },
                    ["@function.method"]         = { fg = c.blue },
                    -- Go builtins (make, len, cap, append) → pink (#f5c2e7)
                    ["@function.builtin"]        = { fg = c.pink },
                    -- Parameters → peach italic (#fab387)
                    ["@variable.parameter"]      = { fg = c.peach, style = { "italic" } },
                    -- Types/Classes → yellow bold (#f9e2af)
                    ["@type"]                    = { fg = c.yellow, style = { "bold" } },
                    ["@type.definition"]         = { fg = c.yellow, style = { "bold" } },
                    ["@type.builtin"]            = { fg = c.yellow, style = { "bold" } },
                    -- Constants & booleans → peach bold
                    ["@constant"]                = { fg = c.peach },
                    ["@constant.builtin"]        = { fg = c.peach, style = { "bold" } },
                    -- Operators → sky (#89dceb)
                    ["@operator"]                = { fg = c.sky },
                    -- Punctuation → overlay2 (#9399b2)
                    ["@punctuation"]             = { fg = c.overlay2 },
                    ["@punctuation.bracket"]     = { fg = c.overlay2 },
                    ["@punctuation.delimiter"]   = { fg = c.overlay2 },
                    -- Properties → lavender (#b4befe)
                    ["@property"]                = { fg = c.lavender },
                    -- Module/package names (Go imports) → green (#a6e3a1)
                    ["@module"]                  = { fg = c.green },
                    -- Language built-in vars (self, this) → red italic
                    ["@variable.builtin"]        = { fg = c.red, style = { "italic" } },
                    -- Strings → green (#a6e3a1)
                    ["@string"]                  = { fg = c.green },
                    -- String interpolation → pink (#f5c2e7)
                    ["@string.special"]          = { fg = c.pink },
                    ["@string.escape"]           = { fg = c.pink },
                    -- Numbers → peach (#fab387)
                    ["@number"]                  = { fg = c.peach },
                    -- Comments → overlay0 italic (#6c7086)
                    ["@comment"]                 = { fg = c.overlay0, style = { "italic" } },
                }
            end,
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
