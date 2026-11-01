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
                ["<Esc>"] = actions.close,
            },
        },
        file_ignore_patterns = { "%.git/", "%.venv/", "__pycache__/", "%.ipynb_checkpoints/" },
    },
    pickers = {
        find_files = { hidden = true },
    },
})
