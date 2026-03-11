local opt = vim.opt

-- Line numbers
opt.number = true
opt.relativenumber = true

-- Indentation
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.smartindent = true

-- Display
opt.wrap = false
opt.termguicolors = true
opt.signcolumn = "yes"
opt.scrolloff = 8
opt.cursorline = true
opt.colorcolumn = "100"

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true

-- Splits
opt.splitright = true
opt.splitbelow = true

-- Performance
opt.updatetime = 250
opt.timeoutlen = 300

-- Persistence
opt.undofile = true
opt.swapfile = false

-- Clipboard (system clipboard)
opt.clipboard = "unnamedplus"

-- Completion
opt.completeopt = { "menu", "menuone", "noselect" }

-- Auto-show diagnostic float when cursor rests on an error
vim.diagnostic.config({
    virtual_text = true,       -- inline hint at end of line
    signs = true,
    underline = true,
    float = { border = "rounded", source = true },
})
vim.api.nvim_create_autocmd("CursorHold", {
    callback = function()
        vim.diagnostic.open_float(nil, { focus = false })
    end,
})

-- Auto-format on save (if LSP supports it)
vim.api.nvim_create_autocmd("BufWritePre", {
    callback = function()
        vim.lsp.buf.format({ async = false })
    end,
})
