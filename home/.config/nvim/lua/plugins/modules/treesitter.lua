return {
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        lazy = false,
        branch = "main",
        config = function()
            require('nvim-treesitter').install({
                'bash',
                'comment',
                'json',
                "lua",
                "markdown",
                "regex",
                "toml",
                "typescript",
                "yaml",
                "c_sharp",
                "go",
                "rust",
                "dart"
            })
        end,
    },
}
