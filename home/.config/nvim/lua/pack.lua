local files = require("lib.files")

vim.pack.add({
    "https://github.com/Mofiqul/vscode.nvim",
    "https://github.com/nvim-lua/plenary.nvim",
    "https://github.com/windwp/nvim-autopairs",
    { src = "https://github.com/Saghen/blink.cmp",                version = vim.version.range("1") },
    { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
    { src = "https://github.com/mrcjkb/rustaceanvim",             version = vim.version.range("^9") },
    "https://github.com/GustavEikaas/easy-dotnet.nvim",
    "https://github.com/mfussenegger/nvim-dap",
    "https://github.com/rcarriga/nvim-dap-ui",
    "https://github.com/nvim-neotest/nvim-nio",
    "https://github.com/nvim-neotest/neotest",
    "https://github.com/nsidorenco/neotest-vstest",
    "https://github.com/danymat/neogen",
    "https://github.com/petertriho/nvim-scrollbar",
})

-- Vscode theme
require("vscode").setup({
    transparent = true,
    italic_comments = true,
    italic_inlayhints = true,
    underline_links = true,
    disable_nvimtree_bg = true,
})

-- Autopairs
require("nvim-autopairs").setup()

-- Treesitter
local treesitter_languages = {
    "bash",
    "c_sharp",
    "css",
    "go",
    "gomod",
    "gosum",
    "gotmpl",
    "html",
    "javascript",
    "json",
    "lua",
    "markdown",
    "markdown_inline",
    "proto",
    "rust",
    "scss",
    "tsx",
    "typescript",
    "vue",
    "yaml",
}

require("nvim-treesitter").setup()
require("nvim-treesitter").install(treesitter_languages)
vim.treesitter.language.register("bash", "sh")
vim.treesitter.language.register("c_sharp", "cs")
vim.treesitter.language.register("javascript", "javascriptreact")
vim.treesitter.language.register("json", "jsonc")
vim.treesitter.language.register("tsx", "typescriptreact")
vim.treesitter.language.register("yaml", "buf-config")

vim.api.nvim_create_autocmd("FileType", {
    pattern = vim.list_extend(vim.deepcopy(treesitter_languages), {
        "buf-config",
        "cs",
        "javascriptreact",
        "jsonc",
        "sh",
        "typescriptreact",
    }),
    callback = function()
        pcall(vim.treesitter.start)
    end,
    desc = "Enable treesitter highlighting",
})

-- Completion
require("blink.cmp").setup({
    keymap = {
        preset = "default",
        ["<CR>"] = { "accept", "fallback" },
        ["<Tab>"] = { "select_next", "fallback" },
        ["<S-Tab>"] = { "select_prev", "fallback" },
        ["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
        ["<C-e>"] = { "hide" },
    },
    fuzzy = {
        implementation = "rust",
    },
    appearance = {
        use_nvim_cmp_as_default = true,
        nerd_font_variant = "mono",
    },
    completion = {
        menu = { border = "none" },
        documentation = { auto_show = true },
    },
    sources = {
        default = { "lsp", "path", "snippets", "buffer" },
    },
})

-- rustaceanvim manages rust-analyzer itself and does not auto-detect blink, so
-- pass blink's capabilities explicitly (matching the other LSP servers).
vim.g.rustaceanvim = {
    server = {
        capabilities = require("blink.cmp").get_lsp_capabilities(),
    },
}

-- Dotnet
local function setup_easy_dotnet()
    require("easy-dotnet").setup({
        auto_bootstrap_namespace = {
            type = "file_scoped",
            enabled = true,
        },
        test_runner = {
            neotest_integration = true,
        },
        debugger = {
            auto_register_dap = false,
        },
        lsp = {
            enabled = true,
            auto_refresh_codelens = false,
            config = {
                capabilities = require("blink.cmp").get_lsp_capabilities(),
            },
        },
    })
end

vim.api.nvim_create_autocmd("FileType", {
    pattern = "cs",
    once = true,
    callback = setup_easy_dotnet,
    desc = "Set up easy-dotnet for C# buffers",
})

-- Neotest
--
-- rustaceanvim's neotest adapter root() shells out to `cargo metadata` and reads
-- vim.env synchronously. neotest probes every registered adapter's root() inside
-- an async (fast event) context, where those calls raise E5560. Replace root()
-- with a fast-safe filesystem walk so probing non-Rust projects (e.g. dotnet) no
-- longer crashes neotest.
local rust_neotest = require("rustaceanvim.neotest")

rust_neotest.root = function(path)
    local markers = vim.fs.find({ "Cargo.toml", "rust-project.json" }, {
        upward = true,
        path = path,
    })
    if #markers == 0 then
        return nil
    end

    local workspace_root = vim.fs.dirname(markers[1])

    for dir in vim.fs.parents(markers[1]) do
        local manifest = dir .. "/Cargo.toml"
        if vim.uv.fs_stat(manifest) then
            local content = files.read(manifest)
            if content and content:match("%f[%[]%[workspace%]") then
                workspace_root = dir
            end
        end
    end

    return workspace_root
end

require("neotest").setup({
    adapters = {
        require("neotest-vstest"),
        rust_neotest,
    },
})

-- neotest-vstest emits positions of type "parameterized", which neotest's
-- status consumer never registers a sign for, causing E155 on sign_place.
vim.fn.sign_define("neotest_parameterized", {
    text = require("neotest.config").icons.namespace,
    texthl = require("neotest.config").highlights.namespace,
})

-- Neogen
require("neogen").setup({
    snippet_engine = "nvim",
    languages = {
        cs = {
            template = {
                annotation_convention = "xmldoc",
            },
        },
    },
})

-- Diagnostic overview
require("scrollbar").setup({
    handlers = {
        cursor = true,
        diagnostic = true,
        gitsigns = false,
        handle = false,
        search = false,
        ale = false,
    },
})
