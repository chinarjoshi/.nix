-- Global keymaps. LSP keymaps live in config/lsp.lua (they only make sense once a
-- server attaches); plugin keymaps live next to their plugin spec.

local map = vim.keymap.set

map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

-- Windows
map("n", "<C-h>", "<C-w>h", { desc = "Window left" })
map("n", "<C-j>", "<C-w>j", { desc = "Window down" })
map("n", "<C-k>", "<C-w>k", { desc = "Window up" })
map("n", "<C-l>", "<C-w>l", { desc = "Window right" })

-- Buffers
map("n", "<S-h>", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
map("n", "<S-l>", "<cmd>bnext<CR>", { desc = "Next buffer" })
map("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Delete buffer" })

-- Keep the cursor centred while scrolling and searching
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")

-- Move the visual selection up/down, reindenting as it goes
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Stay in visual mode when shifting
map("v", "<", "<gv")
map("v", ">", ">gv")

-- Paste over a selection without clobbering the unnamed register
map("x", "<leader>p", [["_dP]], { desc = "Paste (keep register)" })

-- Built-in file browser; no plugin required
map("n", "<leader>e", "<cmd>Explore<CR>", { desc = "Explore (netrw)" })

-- Diagnostics ([d and ]d to jump are built-in defaults on 0.11)
map("n", "<leader>xd", vim.diagnostic.open_float, { desc = "Diagnostic: line float" })
map("n", "<leader>xq", vim.diagnostic.setloclist, { desc = "Diagnostic: to loclist" })

-- Escape out of :terminal insert mode
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Terminal: normal mode" })
