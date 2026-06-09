return {
    {
        "numToStr/Comment.nvim",
        keys = {
            { "<leader>k", desc = "Toggle line comment" },
            { "<leader>u", desc = "Toggle comment (op)", mode = { "n", "v" } },
        },
        config = function()
            require("Comment").setup({
                toggler = {
                    line = "<leader>k",
                },
                opleader = {
                    line = "<leader>u",
                },
            })
        end,
    },
    {
        "lukas-reineke/indent-blankline.nvim",
        main = "ibl",
        event = "BufReadPre",
        config = function()
            vim.opt.list = true
            require("ibl").setup()
        end,
    },
    {
        "RRethy/vim-illuminate",
        event = { "BufReadPost", "BufNewFile" },
        config = function()
            require("illuminate").configure({
                providers = {
                    "lsp",
                    "treesitter",
                    "regex",
                },
                delay = 0,
            })
        end,
    },
    {
        "windwp/nvim-autopairs",
        event = "InsertEnter",
        config = function()
            local npairs = require("nvim-autopairs")
            npairs.setup()
        end,
    },
}
