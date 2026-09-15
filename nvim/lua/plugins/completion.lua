-- blink.cmp: completion engine. Under Nix the Rust fuzzy matcher is built as
-- part of the plugin derivation, so there is no download step and no cargo
-- fallback to worry about -- `prefer_rust_with_warning` will always take the
-- Rust path here. friendly-snippets is a Nix dependency rather than a spec one.
require("blink.cmp").setup({
    -- "enter"    : <CR> accepts, <C-n>/<C-p> cycle, <C-space> opens menu
    -- "default"  : <C-y> accepts, <CR> always inserts a newline
    -- "super-tab": <Tab> accepts
    keymap = { preset = "enter" },

    appearance = { nerd_font_variant = "mono" },

    completion = {
        -- The menu still opens on its own; the big documentation panel beside
        -- it does not. <C-space> pulls docs up on demand (the "enter" preset
        -- binds show / show_documentation / hide_documentation to it), and
        -- <C-b>/<C-f> scroll them.
        documentation = { auto_show = false },
        menu = { border = "rounded" },
        ghost_text = { enabled = false },
    },

    -- Parameter hints used to pop up unprompted while typing a call. K and the
    -- LSP float still show the signature when asked.
    signature = { enabled = false },

    -- LSP only. `buffer` proposed every word already on the page, and
    -- `snippets` (friendly-snippets) is where `in`/`for` came from -- both were
    -- noise layered on top of real completions. `path` went with them; add it
    -- back to this list if you miss filepath completion.
    sources = { default = { "lsp" } },

    fuzzy = { implementation = "prefer_rust_with_warning" },
})
