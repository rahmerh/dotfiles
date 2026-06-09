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
    "https://github.com/Weissle/persistent-breakpoints.nvim",
    "https://github.com/nvim-neotest/neotest",
    "https://github.com/nsidorenco/neotest-vstest",
    "https://github.com/RRethy/vim-illuminate",
    "https://github.com/numToStr/Comment.nvim",
    "https://github.com/danymat/neogen",
    "https://github.com/echasnovski/mini.hipatterns",
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

-- Illuminate
require("illuminate").configure({
    delay = 100,
    disable_keymaps = true,
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
require("neotest").setup({
    adapters = {
        require("neotest-vstest"),
        require("rustaceanvim.neotest"),
    },
})

-- Comment.nvim
require("Comment").setup()

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

-- Hipatterns
local hipatterns = require("mini.hipatterns")
hipatterns.setup({
    highlighters = {
        hex_color = hipatterns.gen_highlighter.hex_color(),
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
