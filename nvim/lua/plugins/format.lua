require("conform").setup({
    formatters_by_ft = {
        python = { "ruff_organize_imports", "ruff_format" },
        lua = { "stylua" }, -- skipped unless stylua is on PATH
    },
    -- Returning nil skips formatting, which is how the toggle below works.
    format_on_save = function(bufnr)
        if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
            return
        end
        return { timeout_ms = 1500, lsp_format = "fallback" }
    end,
})

-- :FormatToggle  -> global, :FormatToggle! -> this buffer only
vim.api.nvim_create_user_command("FormatToggle", function(args)
    if args.bang then
        vim.b.disable_autoformat = not vim.b.disable_autoformat
        vim.notify("Buffer autoformat: " .. (vim.b.disable_autoformat and "off" or "on"))
    else
        vim.g.disable_autoformat = not vim.g.disable_autoformat
        vim.notify("Global autoformat: " .. (vim.g.disable_autoformat and "off" or "on"))
    end
end, { bang = true, desc = "Toggle format-on-save" })
