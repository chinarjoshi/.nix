-- Parsers come from `nvim-treesitter.withPlugins` in common.nix.
require("nvim-treesitter").setup({})

vim.api.nvim_create_autocmd("FileType", {
    desc = "Start treesitter highlighting and indenting where a parser exists",
    group = vim.api.nvim_create_augroup("treesitter-start", { clear = true }),
    callback = function(args)
        local ft = vim.bo[args.buf].filetype
        local lang = vim.treesitter.language.get_lang(ft)
        if not lang then
            return
        end

        -- Without a parser for this language, stay on regex highlighting.
        if not pcall(vim.treesitter.start, args.buf, lang) then
            return
        end

        -- Python uses the built-in ftplugin's indenting.
        if ft ~= "python" then
            vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
    end,
})
