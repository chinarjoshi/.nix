-- Editor behaviour. Pure vim options -- moved to Nix untouched, as planned.

-- Leader must be set before any module that declares <leader> maps is required.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local o = vim.o

-- Lines & navigation
o.number = true
o.relativenumber = true
o.cursorline = true
o.scrolloff = 8
o.sidescrolloff = 8
o.wrap = false

-- Indentation: 4 spaces (PEP 8). Filetype plugins may override per language.
o.expandtab = true
o.shiftwidth = 4
o.tabstop = 4
o.softtabstop = 4
o.smartindent = true

-- Search
o.ignorecase = true
o.smartcase = true
o.incsearch = true
o.hlsearch = true

-- Splits
o.splitright = true
o.splitbelow = true

-- Files: persistent undo instead of swap/backup clutter
o.undofile = true
o.swapfile = false
o.backup = false
o.confirm = true -- prompt instead of failing when quitting a dirty buffer

-- UI
o.termguicolors = true
o.signcolumn = "yes" -- always reserve the gutter so text doesn't jump
o.winborder = "rounded" -- 0.11+: borders on hover/diagnostic/signature floats
o.showmode = false -- lualine already renders the mode
o.pumheight = 10
o.updatetime = 250
o.timeoutlen = 400

o.clipboard = "unnamedplus" -- share the macOS system clipboard
o.mouse = "a" -- set to "" if you want it fully off

-- Surface whitespace that silently breaks Python indentation
o.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

vim.api.nvim_create_autocmd("TextYankPost", {
    desc = "Briefly highlight yanked text",
    group = vim.api.nvim_create_augroup("highlight-yank", { clear = true }),
    callback = function()
        vim.hl.on_yank()
    end,
})
