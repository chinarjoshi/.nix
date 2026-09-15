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
        documentation = { auto_show = true, auto_show_delay_ms = 200 },
        menu = { border = "rounded" },
        ghost_text = { enabled = false },
    },

    signature = { enabled = true }, -- parameter hints while typing a call

    sources = { default = { "lsp", "path", "snippets", "buffer" } },

    fuzzy = { implementation = "prefer_rust_with_warning" },
})
