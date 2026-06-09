return {
    {
        "saghen/blink.cmp",
        version = '1.*',
        event = "InsertEnter",
        dependencies = {
            "rafamadriz/friendly-snippets",
            "L3MON4D3/LuaSnip",
        },
        opts = {
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
            snippets = { preset = "luasnip" },
        },
    },
}
