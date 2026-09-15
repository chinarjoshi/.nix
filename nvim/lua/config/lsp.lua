-- Language servers, using Neovim 0.11's built-in vim.lsp.config/vim.lsp.enable.
-- No nvim-lspconfig, no mason: the binaries already come from Nix, and this file
-- is plain Lua that ports to programs.neovim unchanged.

-- 1. Capabilities -------------------------------------------------------------
-- Advertise blink.cmp's extra completion capabilities to every server. pcall so
-- the config still loads cleanly if the plugin is missing or not yet installed.
local capabilities = vim.lsp.protocol.make_client_capabilities()
local ok, blink = pcall(require, "blink.cmp")
if ok then
    capabilities = blink.get_lsp_capabilities(capabilities)
end
vim.lsp.config("*", { capabilities = capabilities })

-- 2. Python interpreter resolution --------------------------------------------
-- Pyright resolves imports against one interpreter. Without this it picks the
-- first `python3` on PATH and every `import torch` lights up red. Order:
-- an activated venv, else the nearest .venv walking up from the file.
local function python_path(root)
    if vim.env.VIRTUAL_ENV and vim.env.VIRTUAL_ENV ~= "" then
        return vim.env.VIRTUAL_ENV .. "/bin/python"
    end
    local found = vim.fs.find("\46venv", { path = root or vim.fn.getcwd(), upward = true, type = "directory" })[1]
    if found then
        local exe = found .. "/bin/python"
        if vim.uv.fs_stat(exe) then
            return exe
        end
    end
    return vim.fn.exepath("python3")
end

local python_roots = {
    "pyproject.toml",
    "uv.lock",
    "setup.py",
    "setup.cfg",
    "requirements.txt",
    ".git",
}

-- 3. Server definitions --------------------------------------------------------
-- pyright: types, completion, go-to-definition. Import organising is left to
-- ruff so the two don't fight over the same edit.
vim.lsp.config("pyright", {
    cmd = { "pyright-langserver", "--stdio" },
    filetypes = { "python" },
    root_markers = python_roots,
    before_init = function(_, config)
        config.settings.python.pythonPath = python_path(config.root_dir)
    end,
    settings = {
        pyright = { disableOrganizeImports = true },
        python = {
            analysis = {
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                diagnosticMode = "openFilesOnly", -- "workspace" is much slower on big repos
                typeCheckingMode = "basic", -- "off" | "basic" | "strict"
            },
        },
    },
})

-- ruff: linting + formatting via its built-in language server.
vim.lsp.config("ruff", {
    cmd = { "ruff", "server" },
    filetypes = { "python" },
    root_markers = python_roots,
})

-- lua_ls: so editing this config is not a guessing game.
vim.lsp.config("lua_ls", {
    cmd = { "lua-language-server" },
    filetypes = { "lua" },
    root_markers = { ".luarc.json", ".luarc.jsonc", ".git" },
    settings = {
        Lua = {
            runtime = { version = "LuaJIT" },
            diagnostics = { globals = { "vim" } },
            workspace = {
                library = vim.api.nvim_get_runtime_file("", true),
                checkThirdParty = false,
            },
            telemetry = { enable = false },
        },
    },
})

-- Enable only the servers actually present on PATH, so a missing binary is a
-- silent no-op rather than an error box on every file open.
for _, name in ipairs({ "pyright", "ruff", "lua_ls" }) do
    local cmd = vim.lsp.config[name].cmd[1]
    if vim.fn.executable(cmd) == 1 then
        vim.lsp.enable(name)
    else
        vim.notify(("LSP %s disabled: %s not on PATH"):format(name, cmd), vim.log.levels.WARN)
    end
end

-- 4. Diagnostics presentation ---------------------------------------------------
vim.diagnostic.config({
    virtual_text = { prefix = "●", spacing = 2 },
    severity_sort = true,
    underline = true,
    update_in_insert = false, -- don't churn diagnostics mid-keystroke
    float = { source = true },
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = "E",
            [vim.diagnostic.severity.WARN] = "W",
            [vim.diagnostic.severity.INFO] = "I",
            [vim.diagnostic.severity.HINT] = "H",
        },
    },
})

-- 5. Per-buffer setup on attach --------------------------------------------------
vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
    callback = function(event)
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        local function map(keys, fn, desc)
            vim.keymap.set("n", keys, fn, { buffer = event.buf, desc = "LSP: " .. desc })
        end

        -- 0.11 already binds grn (rename), gra (code action), grr (references),
        -- gri (implementation) and K (hover). These are the familiar aliases.
        map("gd", vim.lsp.buf.definition, "Go to definition")
        map("gD", vim.lsp.buf.declaration, "Go to declaration")
        map("gr", vim.lsp.buf.references, "References")
        map("gI", vim.lsp.buf.implementation, "Implementation")
        map("gy", vim.lsp.buf.type_definition, "Type definition")
        map("<leader>rn", vim.lsp.buf.rename, "Rename symbol")
        map("<leader>ca", vim.lsp.buf.code_action, "Code action")
        map("<leader>ih", function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }), { bufnr = event.buf })
        end, "Toggle inlay hints")

        -- ruff's hover is empty; let pyright own hover for Python buffers.
        if client and client.name == "ruff" then
            client.server_capabilities.hoverProvider = false
        end
    end,
})
