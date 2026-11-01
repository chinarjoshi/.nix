local capabilities = vim.lsp.protocol.make_client_capabilities()
local ok, blink = pcall(require, "blink.cmp")
if ok then
    capabilities = blink.get_lsp_capabilities(capabilities)
end
vim.lsp.config("*", { capabilities = capabilities })

-- Pyright resolves imports against one interpreter: the active venv, then the
-- nearest .venv, then python3 on PATH.
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

-- Import organizing is left to ruff so the two servers don't conflict.
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

vim.lsp.config("ruff", {
    cmd = { "ruff", "server" },
    filetypes = { "python" },
    root_markers = python_roots,
})

for _, name in ipairs({ "pyright", "ruff" }) do
    local cmd = vim.lsp.config[name].cmd[1]
    if vim.fn.executable(cmd) == 1 then
        vim.lsp.enable(name)
    else
        vim.notify(("LSP %s disabled: %s not on PATH"):format(name, cmd), vim.log.levels.WARN)
    end
end

vim.diagnostic.config({
    virtual_text = false,
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

vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
    callback = function(event)
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        local function map(keys, fn, desc)
            vim.keymap.set("n", keys, fn, { buffer = event.buf, desc = "LSP: " .. desc })
        end

        map("gd", vim.lsp.buf.definition, "Go to definition")
        map("gD", vim.lsp.buf.declaration, "Go to declaration")
        map("gr", vim.lsp.buf.references, "References")
        map("gI", vim.lsp.buf.implementation, "Implementation")
        map("gy", vim.lsp.buf.type_definition, "Type definition")

        -- ruff's hover is empty, so pyright handles it.
        if client and client.name == "ruff" then
            client.server_capabilities.hoverProvider = false
        end
    end,
})
