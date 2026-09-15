-- Colourscheme, statusline, git gutter, keymap discovery.
-- Nix puts these on the packpath, so there is no spec table any more -- the
-- bodies are exactly the `config = function()` blocks from the lazy.nvim spec,
-- run in load order instead of by event.

-- Colourscheme first, so nothing renders in the default palette.
require("tokyonight").setup({
    style = "night", -- storm | moon | night | day
    styles = { comments = { italic = true } },

    -- Pure black background. on_colors runs AFTER tokyonight derives
    -- bg_popup/bg_statusline/bg_sidebar/bg_float from bg and bg_dark, so
    -- overriding bg alone would leave floats and the statusline on #1a1b26 --
    -- every one has to be set by hand.
    on_colors = function(colors)
        colors.bg = "#000000"
        colors.bg_dark = "#000000"
        colors.bg_popup = "#000000"
        colors.bg_statusline = "#000000"
        colors.bg_sidebar = "#000000"
        colors.bg_float = "#000000"
        -- `border` was blended against the old bg and is now near-invisible
        -- on black; lift it to the gutter grey so float outlines still read.
        colors.border = colors.fg_gutter
    end,

    on_highlights = function(hl, c)
        -- Unused variables/imports: tokyonight dims these to terminal_black
        -- (#414868), which is ~2.5:1 against black -- unreadable. Drop the fg
        -- override entirely so the token keeps its normal syntax colour, and
        -- mark it with an undercurl instead of by dimming.
        hl.DiagnosticUnnecessary = { undercurl = true, sp = c.orange }
    end,
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
