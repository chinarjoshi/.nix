-- Treesitter: real syntax trees instead of regex highlighting.
--
-- This is the one spec that did NOT port 1:1. nixpkgs ships the `main`-branch
-- rewrite of nvim-treesitter (0.10.0-unstable), which deleted the whole
-- `nvim-treesitter.configs` module the old `master` API was built around:
--
--   ensure_installed / auto_install -> gone. Grammars are a Nix closure now;
--       see `nvim-treesitter.withPlugins` in common.nix. Adding a language
--       means editing that list and rebuilding, not `:TSInstall`.
--   highlight = { enable = true }   -> gone. Call vim.treesitter.start() per
--       buffer, which is what the old module did internally anyway.
--   indent = { enable = true, ... } -> gone. Set 'indentexpr' to the function
--       the plugin still exports.
--   incremental_selection          -> removed upstream with no replacement.
--       The <CR>/<BS> grow/shrink maps are NOT reinstated here.
--
-- setup() only configures the installer (install_dir and friends); with Nix
-- supplying the parsers there is nothing to pass it.
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

        -- pcall: a filetype can map to a language whose parser is not in the
        -- Nix closure. Silently fall back to regex syntax rather than erroring
        -- on every file open.
        if not pcall(vim.treesitter.start, args.buf, lang) then
            return
        end

        -- Treesitter indent for Python is imperfect on continuation lines;
        -- disable it there and let the built-in ftplugin handle indenting.
        if ft ~= "python" then
            vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
    end,
})
