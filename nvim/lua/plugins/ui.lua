-- Colourscheme, statusline, git gutter, keymap discovery.
-- Nix puts these on the packpath, so there is no spec table any more -- the
-- bodies are exactly the `config = function()` blocks from the lazy.nvim spec,
-- run in load order instead of by event.

-- Colourscheme first, so nothing renders in the default palette.
require("tokyonight").setup({
    style = "night", -- storm | moon | night | day
    styles = { comments = { italic = true } },
})
vim.cmd.colorscheme("tokyonight")

require("lualine").setup({
    options = {
        theme = "tokyonight",
        globalstatus = true, -- one statusline, not one per split
        section_separators = "",
        component_separators = "|",
    },
    sections = {
        lualine_c = { { "filename", path = 1 } }, -- path relative to cwd
        lualine_x = { "diagnostics", "filetype" },
    },
})

require("gitsigns").setup({
    on_attach = function(bufnr)
        local gs = require("gitsigns")
        local function map(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
        end
        map("n", "]c", function()
            gs.nav_hunk("next")
        end, "Next git hunk")
        map("n", "[c", function()
            gs.nav_hunk("prev")
        end, "Previous git hunk")
        map("n", "<leader>gp", gs.preview_hunk, "Preview hunk")
        map("n", "<leader>gb", gs.blame_line, "Blame line")
        map("n", "<leader>gr", gs.reset_hunk, "Reset hunk")
        map("n", "<leader>gd", gs.diffthis, "Diff this file")
    end,
})

require("which-key").setup({})
