local capabilities = vim.lsp.protocol.make_client_capabilities()
local blink_ok, blink = pcall(require, "blink.cmp")

if blink_ok then
    capabilities = blink.get_lsp_capabilities(capabilities)
end

local function setup_server(name, config)
    config.capabilities = vim.tbl_deep_extend("force", capabilities, config.capabilities or {})

    vim.lsp.config(name, config)

    if vim.fn.executable(config.cmd[1]) == 1 then
        vim.lsp.enable(name)
    end
end

local vue_language_server_path = "/usr/lib/node_modules/@vue/language-server"
local typescript_path = "/usr/lib/node_modules/typescript"
local vue_typescript_plugins = {}

if vim.fn.isdirectory(vue_language_server_path) == 1 then
    vue_typescript_plugins = {
        {
            name = "@vue/typescript-plugin",
            location = vue_language_server_path,
            languages = { "vue" },
            configNamespace = "typescript",
        },
    }
end

local function forward_vue_tsserver_requests(client)
    client.handlers["tsserver/request"] = function(_, result, context)
        local clients = vim.lsp.get_clients({ bufnr = context.bufnr, name = "ts_ls" })

        if #clients == 0 then
            vim.notify("Could not find ts_ls client for vue_ls request forwarding", vim.log.levels.ERROR)
            return
        end

        local params = unpack(result)
        local id, command, payload = unpack(params)

        clients[1]:exec_cmd({
            title = "vue_request_forward",
            command = "typescript.tsserverRequest",
            arguments = {
                command,
                payload,
            },
        }, { bufnr = context.bufnr }, function(_, response)
            local response_data = { { id, response and response.body } }
            client:notify("tsserver/response", response_data)
        end)
    end
end

vim.filetype.add({
    filename = {
        ["buf.yaml"] = "buf-config",
        ["buf.gen.yaml"] = "buf-config",
        ["buf.lock"] = "buf-config",
        ["buf.policy.yaml"] = "buf-config",
    },
})

vim.diagnostic.config({
    virtual_text = true,
    signs = true,
    underline = true,
    update_in_insert = false,
    severity_sort = true,
})

local servers = {
    lua_ls = {
        cmd = { "lua-language-server" },
        filetypes = { "lua" },
        root_markers = {
            ".luarc.json",
            ".luarc.jsonc",
            ".luacheckrc",
            ".stylua.toml",
            "stylua.toml",
            "selene.toml",
            "selene.yml",
            ".git",
        },
        settings = {
            Lua = {
                diagnostics = {
                    globals = { "vim" },
                },
                runtime = {
                    version = "LuaJIT",
                },
                workspace = {
                    checkThirdParty = false,
                    library = {
                        vim.env.VIMRUNTIME,
                    },
                },
            },
        },
    },

    gopls = {
        cmd = { "gopls" },
        filetypes = { "go", "gomod", "gowork", "gotmpl" },
        root_markers = {
            "go.work",
            "go.mod",
            ".git",
        },
    },

    bashls = {
        cmd = { "bash-language-server", "start" },
        filetypes = { "bash", "sh" },
        root_markers = {
            ".git",
        },
    },

    jsonls = {
        cmd = { "vscode-json-languageserver", "--stdio" },
        filetypes = { "json", "jsonc" },
        root_markers = {
            "package.json",
            ".git",
        },
        init_options = {
            provideFormatter = true,
        },
    },

    html = {
        cmd = { "vscode-html-language-server", "--stdio" },
        filetypes = { "html" },
        root_markers = {
            "package.json",
            ".git",
        },
        init_options = {
            provideFormatter = true,
        },
    },

    cssls = {
        cmd = { "vscode-css-language-server", "--stdio" },
        filetypes = { "css", "scss", "less" },
        root_markers = {
            "package.json",
            ".git",
        },
        init_options = {
            provideFormatter = true,
        },
    },

    cspell_lsp = {
        cmd = { "cspell-lsp", "--stdio" },
        root_markers = {
            "cspell.json",
            ".cspell.json",
            "cspell.config.json",
            "cspell.config.yaml",
            "cspell.config.yml",
            "cspell.config.js",
            "cspell.config.cjs",
            "cspell.config.mjs",
            "package.json",
            ".git",
        },
    },

    ts_ls = {
        cmd = { "typescript-language-server", "--stdio" },
        filetypes = {
            "javascript",
            "javascript.jsx",
            "javascriptreact",
            "typescript",
            "typescript.tsx",
            "typescriptreact",
            "vue",
        },
        root_markers = {
            "tsconfig.json",
            "jsconfig.json",
            "package.json",
            ".git",
        },
        init_options = {
            plugins = vue_typescript_plugins,
        },
        on_attach = function(client, bufnr)
            if vim.bo[bufnr].filetype == "vue" and client.server_capabilities.semanticTokensProvider then
                client.server_capabilities.semanticTokensProvider.full = false
            end
        end,
    },

    vue_ls = {
        cmd = { "vue-language-server", "--stdio" },
        filetypes = { "vue" },
        root_markers = {
            "vue.config.js",
            "vue.config.ts",
            "vite.config.js",
            "vite.config.ts",
            "nuxt.config.js",
            "nuxt.config.ts",
            "package.json",
            ".git",
        },
        init_options = {
            typescript = {
                tsdk = vim.fn.isdirectory(typescript_path) == 1 and (typescript_path .. "/lib") or nil,
            },
        },
        on_init = forward_vue_tsserver_requests,
    },

    buf_ls = {
        cmd = { "buf", "lsp", "serve" },
        filetypes = { "proto", "buf-config" },
        root_markers = {
            "buf.yaml",
            ".git",
        },
    },
}

for name, config in pairs(servers) do
    setup_server(name, config)
end

local function format_lsp_buffers(client)
    local bufnrs = vim.tbl_keys(client.attached_buffers or {})
    table.sort(bufnrs)

    if #bufnrs == 0 then
        return { "    No attached buffers" }
    end

    return vim.tbl_map(function(bufnr)
        local name = vim.api.nvim_buf_get_name(bufnr)
        if name == "" then
            name = "[No Name]"
        else
            name = vim.fn.fnamemodify(name, ":~:.")
        end

        return string.format("    %d  %s", bufnr, name)
    end, bufnrs)
end

local function lsp_info()
    local clients = vim.lsp.get_clients()
    local lines = {
        "LSP Clients",
        string.rep("=", 11),
        "",
    }

    if #clients == 0 then
        table.insert(lines, "No active LSP clients")
    else
        table.sort(clients, function(left, right)
            return left.name < right.name
        end)

        for index, client in ipairs(clients) do
            local root = client.config.root_dir or "-"
            local cmd = client.config.cmd and table.concat(client.config.cmd, " ") or "-"

            table.insert(lines, string.format("%s [%d]", client.name, client.id))
            table.insert(lines, string.format("  root: %s", vim.fn.fnamemodify(root, ":~:.")))
            table.insert(lines, string.format("  cmd:  %s", cmd))
            table.insert(lines, "  attached buffers:")
            vim.list_extend(lines, format_lsp_buffers(client))

            if index < #clients then
                table.insert(lines, "")
            end
        end
    end

    local width = 0
    for _, line in ipairs(lines) do
        width = math.max(width, vim.fn.strdisplaywidth(line))
    end

    width = math.min(math.max(width + 4, 50), math.floor(vim.o.columns * 0.9))
    local height = math.min(#lines, math.floor(vim.o.lines * 0.8))

    local buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].filetype = "lspinfo"
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false

    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = math.floor((vim.o.lines - height) / 2),
        col = math.floor((vim.o.columns - width) / 2),
        style = "minimal",
        border = "rounded",
        title = " LspInfo ",
        title_pos = "center",
    })

    vim.wo[win].wrap = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, silent = true })
    vim.keymap.set("n", "<Esc>", "<cmd>close<cr>", { buffer = buf, silent = true })
end

vim.api.nvim_create_user_command("LspInfo", lsp_info, {
    desc = "Show active LSP clients and attached buffers",
})

local group = vim.api.nvim_create_augroup("UserLspAutocommands", { clear = true })

vim.api.nvim_create_autocmd("LspAttach", {
    group = group,
    callback = function(event)
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if not client or not client:supports_method("textDocument/documentHighlight") then
            return
        end

        local buf = event.buf
        local highlight_group = vim.api.nvim_create_augroup("UserLspDocumentHighlight", { clear = false })
        vim.api.nvim_clear_autocmds({ group = highlight_group, buffer = buf })

        vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
            group = highlight_group,
            buffer = buf,
            callback = vim.lsp.buf.document_highlight,
        })

        vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
            group = highlight_group,
            buffer = buf,
            callback = vim.lsp.buf.clear_references,
        })
    end,
})

vim.api.nvim_create_autocmd("LspDetach", {
    group = group,
    callback = function(event)
        vim.lsp.buf.clear_references()
        pcall(vim.api.nvim_clear_autocmds, {
            group = "UserLspDocumentHighlight",
            buffer = event.buf,
        })
    end,
})
