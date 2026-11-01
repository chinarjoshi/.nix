-- Telescope: fuzzy finder over files, grep, buffers and LSP symbols.
-- Uses the ripgrep already on your PATH for live_grep.
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

-- Pickers are bound under the Doom-style leader tree in config/leader.lua.
