-- Telescope: fuzzy finder over files, grep, buffers and LSP symbols.
-- Uses the ripgrep already on your PATH for <leader>fg.
-- The lazy.nvim `keys = {...}` block became plain vim.keymap.set calls; plenary
-- is a Nix dependency now rather than a `dependencies` entry.

local actions = require("telescope.actions")

require("telescope").setup({
    defaults = {
        path_display = { "truncate" },
        sorting_strategy = "ascending",
        layout_config = { prompt_position = "top" },
        mappings = {
            i = {
                ["<C-j>"] = actions.move_selection_next,
                ["<C-k>"] = actions.move_selection_previous,
                ["<Esc>"] = actions.close, -- one Esc closes, no normal mode detour
            },
        },
        file_ignore_patterns = { "%.git/", "%.venv/", "__pycache__/", "%.ipynb_checkpoints/" },
    },
    pickers = {
        find_files = { hidden = true },
    },
})

local map = vim.keymap.set
map("n", "<leader>ff", "<cmd>Telescope find_files<CR>", { desc = "Find files" })
map("n", "<leader>fg", "<cmd>Telescope live_grep<CR>", { desc = "Grep project" })
map("n", "<leader>fb", "<cmd>Telescope buffers<CR>", { desc = "Buffers" })
map("n", "<leader>fh", "<cmd>Telescope help_tags<CR>", { desc = "Help tags" })
map("n", "<leader>fr", "<cmd>Telescope oldfiles<CR>", { desc = "Recent files" })
map("n", "<leader>fw", "<cmd>Telescope grep_string<CR>", { desc = "Grep word under cursor" })
map("n", "<leader>fd", "<cmd>Telescope diagnostics<CR>", { desc = "Diagnostics" })
map("n", "<leader>fs", "<cmd>Telescope lsp_document_symbols<CR>", { desc = "Document symbols" })
map("n", "<leader>fS", "<cmd>Telescope lsp_dynamic_workspace_symbols<CR>", { desc = "Workspace symbols" })
