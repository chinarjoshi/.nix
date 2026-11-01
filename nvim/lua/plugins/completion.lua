require("blink.cmp").setup({
    keymap = { preset = "enter" },

    appearance = { nerd_font_variant = "mono" },

    completion = {
        documentation = { auto_show = false },
        menu = { border = "rounded" },
        ghost_text = { enabled = false },
    },

    signature = { enabled = false },

    sources = { default = { "lsp" } },

    fuzzy = { implementation = "prefer_rust_with_warning" },
})
