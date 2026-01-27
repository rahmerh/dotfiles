return {
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        lazy = false,
        config = function()
            require("nvim-treesitter.configs").setup({
                ensured_installed = {
                    "bash",
                    "comment",
                    "json",
                    "lua",
                    "markdown",
                    "regex",
                    "toml",
                    "typescript",
                    "yaml",
                    "c_sharp",
                    "go",
                    "rust"
                },
                auto_install = true,
                highlight = {
                    enable = true,
                    additional_vim_regex_highlighting = true,
                },
                indent = {
                    enable = true
                },
                sync_install = true
            });
        end,
    },
}
