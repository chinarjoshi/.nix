-- Doom Emacs-style <Space> leader tree. Every leader map lives here so the
-- layout reads as one table, like Doom's +default/+evil bindings. Loaded last
-- (see initLua in common.nix) so which-key and every plugin are already set up.
--
-- Not ported, because they need plugins this config doesn't have:
-- SPC p p (switch project), SPC TAB (workspaces), SPC n (org notes) and
-- SPC g g as a real magit (it opens git status in Telescope instead).

local map = vim.keymap.set
local tb = function() return require("telescope.builtin") end
local gs = function() return require("gitsigns") end

-- Project root = nearest .git above the current buffer, else the cwd. This is
-- what projectile does for SPC SPC / SPC / in Doom.
local function root()
    return vim.fs.root(0, ".git") or vim.uv.cwd()
end

local function buf_dir()
    local name = vim.api.nvim_buf_get_name(0)
    return name ~= "" and vim.fs.dirname(name) or vim.uv.cwd()
end

local function leader(lhs, rhs, desc, mode)
    map(mode or "n", "<leader>" .. lhs, rhs, { desc = desc })
end

local function scratch()
    vim.cmd.enew()
    vim.bo.buftype = "nofile"
    vim.bo.bufhidden = "hide"
    vim.bo.swapfile = false
end

-- Top level ---------------------------------------------------------------------
leader("<leader>", function() tb().find_files({ cwd = root() }) end, "Find file in project")
leader(".", function() tb().find_files({ cwd = buf_dir() }) end, "Find file")
leader(",", function() tb().buffers({ sort_mru = true }) end, "Switch buffer")
leader("/", function() tb().live_grep({ cwd = root() }) end, "Search project")
leader("*", function() tb().grep_string({ cwd = root() }) end, "Search project for symbol")
leader(":", function() tb().commands() end, "M-x")
leader("'", function() tb().resume() end, "Resume last search")
leader("`", "<cmd>buffer #<CR>", "Switch to last buffer")
leader("x", scratch, "Pop up scratch buffer")

-- f: file ----------------------------------------------------------------------
leader("ff", function() tb().find_files({ cwd = buf_dir() }) end, "Find file")
leader("fr", function() tb().oldfiles() end, "Recent files")
leader("fs", "<cmd>write<CR>", "Save file")
leader("fS", ":saveas ", "Save file as...")
leader("fp", function() tb().find_files({ cwd = vim.fn.expand("~/nixos/nvim") }) end, "Browse private config")
leader("fy", function()
    local path = vim.fn.expand("%:p")
    vim.fn.setreg("+", path)
    vim.notify("Copied " .. path)
end, "Yank file path")
leader("fY", function()
    local path = vim.fs.relpath(root(), vim.fn.expand("%:p")) or vim.fn.expand("%")
    vim.fn.setreg("+", path)
    vim.notify("Copied " .. path)
end, "Yank file path from project")
leader("fR", function()
    local old = vim.fn.expand("%:p")
    vim.ui.input({ prompt = "Rename to: ", default = old, completion = "file" }, function(new)
        if not new or new == "" or new == old then return end
        vim.fn.mkdir(vim.fs.dirname(new), "p")
        vim.cmd.saveas(vim.fn.fnameescape(new))
        vim.fn.delete(old)
        vim.cmd("silent! bwipeout " .. vim.fn.bufnr(old))
    end)
end, "Rename/move file")
leader("fD", function()
    local path = vim.fn.expand("%:p")
    if vim.fn.confirm("Delete " .. path .. "?", "&Yes\n&No", 2) == 1 then
        vim.fn.delete(path)
        vim.cmd("bdelete!")
    end
end, "Delete this file")

-- b: buffer --------------------------------------------------------------------
leader("bb", function() tb().buffers({ sort_mru = true }) end, "Switch buffer")
leader("bd", "<cmd>bdelete<CR>", "Kill buffer")
leader("bk", "<cmd>bdelete<CR>", "Kill buffer")
leader("bK", "<cmd>%bdelete<CR>", "Kill all buffers")
leader("bO", "<cmd>%bdelete | edit # | bdelete #<CR>", "Kill other buffers")
leader("bn", "<cmd>bnext<CR>", "Next buffer")
leader("bp", "<cmd>bprevious<CR>", "Previous buffer")
leader("b]", "<cmd>bnext<CR>", "Next buffer")
leader("b[", "<cmd>bprevious<CR>", "Previous buffer")
leader("bl", "<cmd>buffer #<CR>", "Switch to last buffer")
leader("bN", "<cmd>enew<CR>", "New empty buffer")
leader("bs", "<cmd>write<CR>", "Save buffer")
leader("bS", "<cmd>wall<CR>", "Save all buffers")
leader("br", "<cmd>edit!<CR>", "Revert buffer")
leader("bx", scratch, "Pop up scratch buffer")
leader("by", "<cmd>%yank +<CR>", "Yank buffer")

-- p: project -------------------------------------------------------------------
leader("pf", function() tb().find_files({ cwd = root() }) end, "Find file in project")
leader("pr", function() tb().oldfiles({ cwd = root(), cwd_only = true }) end, "Recent project files")
leader("pb", function() tb().buffers({ cwd = root(), only_cwd = true }) end, "Switch to project buffer")
leader("pt", function()
    tb().grep_string({ cwd = root(), search = [[\b(TODO|FIXME|HACK|NOTE)\b]], use_regex = true })
end, "List project todos")

-- s: search --------------------------------------------------------------------
leader("ss", function() tb().current_buffer_fuzzy_find() end, "Search buffer")
leader("sb", function() tb().current_buffer_fuzzy_find() end, "Search buffer")
leader("sS", function()
    tb().current_buffer_fuzzy_find({ default_text = vim.fn.expand("<cword>") })
end, "Search buffer for thing at point")
leader("sp", function() tb().live_grep({ cwd = root() }) end, "Search project")
leader("sd", function() tb().live_grep({ cwd = buf_dir() }) end, "Search current directory")
leader("sf", function() tb().find_files({ cwd = root() }) end, "Locate file")
leader("si", function()
    if #vim.lsp.get_clients({ bufnr = 0 }) > 0 then
        tb().lsp_document_symbols()
    else
        tb().treesitter()
    end
end, "Jump to symbol")
leader("sj", function() tb().jumplist() end, "Jump list")
leader("sr", function() tb().marks() end, "Jump to mark")

-- c: code ----------------------------------------------------------------------
leader("ca", vim.lsp.buf.code_action, "Code actions", { "n", "x" })
leader("cr", vim.lsp.buf.rename, "LSP rename")
leader("cf", function()
    require("conform").format({ async = true, lsp_format = "fallback" })
end, "Format buffer/region", { "n", "x" })
leader("cd", vim.lsp.buf.definition, "Jump to definition")
leader("cD", function() tb().lsp_references() end, "Jump to references")
leader("ci", function() tb().lsp_implementations() end, "Find implementations")
leader("ct", vim.lsp.buf.type_definition, "Find type definition")
leader("ck", vim.lsp.buf.hover, "Jump to documentation")
leader("cj", function() tb().lsp_dynamic_workspace_symbols() end, "Jump to symbol in workspace")
leader("cx", function() tb().diagnostics({ bufnr = 0 }) end, "List errors")
leader("cX", function() tb().diagnostics() end, "List project errors")
leader("cw", [[<cmd>keeppatterns %s/\s\+$//e<CR>]], "Delete trailing whitespace")

-- g: git (gitsigns; no magit) ---------------------------------------------------
leader("gg", function() tb().git_status() end, "Git status")
leader("gb", function() tb().git_branches() end, "Switch branch")
leader("gB", function() gs().blame_line({ full = true }) end, "Blame line")
leader("g[", function() gs().nav_hunk("prev") end, "Previous hunk")
leader("g]", function() gs().nav_hunk("next") end, "Next hunk")
leader("gp", function() gs().preview_hunk() end, "Preview hunk")
leader("gs", function() gs().stage_hunk() end, "Stage hunk")
leader("gS", function() gs().stage_buffer() end, "Stage file")
leader("gr", function() gs().reset_hunk() end, "Revert hunk")
leader("gR", function() gs().reset_buffer() end, "Revert file")
leader("gd", function() gs().diffthis() end, "Diff this file")
leader("gs", function() gs().stage_hunk({ vim.fn.line("v"), vim.fn.line(".") }) end, "Stage hunk", "x")
leader("gr", function() gs().reset_hunk({ vim.fn.line("v"), vim.fn.line(".") }) end, "Revert hunk", "x")

-- w: window --------------------------------------------------------------------
leader("wh", "<C-w>h", "Window left")
leader("wj", "<C-w>j", "Window down")
leader("wk", "<C-w>k", "Window up")
leader("wl", "<C-w>l", "Window right")
leader("wH", "<C-w>H", "Move window left")
leader("wJ", "<C-w>J", "Move window down")
leader("wK", "<C-w>K", "Move window up")
leader("wL", "<C-w>L", "Move window right")
leader("ww", "<C-w>w", "Other window")
leader("wv", "<C-w>v", "Split vertically")
leader("ws", "<C-w>s", "Split horizontally")
leader("wd", "<C-w>c", "Delete window")
leader("wc", "<C-w>c", "Close window")
leader("wo", "<C-w>o", "Delete other windows")
leader("w=", "<C-w>=", "Balance windows")
leader("wq", "<C-w>q", "Quit window")
leader("wmm", "<C-w>_<C-w>|", "Maximize window")

-- o: open ----------------------------------------------------------------------
leader("o-", "<cmd>Explore<CR>", "Open file browser here")
leader("ot", "<cmd>botright split | resize 15 | terminal<CR>", "Open terminal popup")
leader("oT", "<cmd>terminal<CR>", "Open terminal here")

-- i: insert --------------------------------------------------------------------
leader("iy", function() tb().registers() end, "From kill ring")

-- t: toggle --------------------------------------------------------------------
leader("tl", "<cmd>set number!<CR>", "Line numbers")
leader("tw", "<cmd>set wrap!<CR>", "Soft line wrapping")
leader("ts", "<cmd>setlocal spell!<CR>", "Spell checker")
leader("tr", "<cmd>setlocal readonly!<CR>", "Read-only mode")
leader("tf", function()
    vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end, "Diagnostics")
leader("tF", "<cmd>FormatToggle<CR>", "Format on save")
leader("ti", function()
    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = 0 }), { bufnr = 0 })
end, "Inlay hints")

-- h: help ----------------------------------------------------------------------
leader("hh", function() tb().help_tags() end, "Help tags")
leader("hk", function() tb().keymaps() end, "Describe key")
leader("ho", function() tb().vim_options() end, "Describe option")
leader("hm", function() tb().man_pages() end, "Man page")
leader("ht", function() tb().colorscheme({ enable_preview = true }) end, "Load theme")

-- q: quit ----------------------------------------------------------------------
leader("qq", "<cmd>quitall<CR>", "Quit")
leader("qQ", "<cmd>quitall!<CR>", "Quit without saving")

-- Visual-mode paste that keeps the register (not Doom, but kept from before).
leader("p", [["_dP]], "Paste (keep register)", "x")

-- which-key group labels --------------------------------------------------------
require("which-key").add({
    { "<leader>b", group = "buffer" },
    { "<leader>c", group = "code" },
    { "<leader>f", group = "file" },
    { "<leader>g", group = "git" },
    { "<leader>h", group = "help" },
    { "<leader>i", group = "insert" },
    { "<leader>o", group = "open" },
    { "<leader>p", group = "project", mode = "n" },
    { "<leader>q", group = "quit" },
    { "<leader>s", group = "search" },
    { "<leader>t", group = "toggle" },
    { "<leader>w", group = "window" },
    { "<leader>wm", group = "maximize" },
})
