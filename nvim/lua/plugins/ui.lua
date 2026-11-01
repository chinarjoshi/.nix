require("tokyonight").setup({
    style = "night", -- storm | moon | night | day
    styles = { comments = { italic = true } },

    -- tokyonight derives the other backgrounds before this runs, so set each one.
    on_colors = function(colors)
        colors.bg = "#000000"
        colors.bg_dark = "#000000"
        colors.bg_popup = "#000000"
        colors.bg_statusline = "#000000"
        colors.bg_sidebar = "#000000"
        colors.bg_float = "#000000"
        -- The default border is nearly invisible on black.
        colors.border = colors.fg_gutter
    end,

    on_highlights = function(hl, c)
        -- The default dimmed color is unreadable on black.
        hl.DiagnosticUnnecessary = { undercurl = true, sp = c.orange }
    end,
})
vim.cmd.colorscheme("tokyonight")

require("lualine").setup({
    options = {
        theme = "tokyonight",
        globalstatus = true, -- one statusline, not one per split
        section_separators = "",
        component_separators = "",
    },
    sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = { { "filename", path = 1 } }, -- path relative to cwd
        lualine_x = {
            {
                "diagnostics",
                symbols = { error = "E", warn = "W", info = "I", hint = "H" },
            },
        },
        lualine_y = {},
        lualine_z = { "location" },
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
    end,
})

require("which-key").setup({})
