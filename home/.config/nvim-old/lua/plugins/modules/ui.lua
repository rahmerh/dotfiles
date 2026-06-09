return {
    {
        "petertriho/nvim-scrollbar",
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            local red = "#ff0000"
            local yellow = "#ffff31"
            local cyan = "#a6e7ff"
            local green = "#32cd32"

            require("scrollbar").setup({
                show_in_active_only = true,
                hide_if_all_visible = true,
                handlers = {
                    diagnostic = true,
                    search = false,
                    gitsigns = false,
                },
                handle = {
                    color = "#7e7e7e",
                },
                marks = {
                    Search = {
                        text = { "-", "=" },
                        priority = 0,
                        color = green,
                        highlight = "Search",
                    },
                    Error = {
                        text = { "-", "=" },
                        priority = 1,
                        color = red,
                        highlight = "DiagnosticVirtualTextError",
                    },
                    Warn = {
                        text = { "-", "=" },
                        priority = 2,
                        color = yellow,
                        highlight = "DiagnosticVirtualTextWarn",
                    },
                    Info = {
                        text = { "-", "=" },
                        priority = 3,
                        color = cyan,
                        highlight = "DiagnosticVirtualTextInfo",
                    },
                    Hint = {
                        text = { "-", "=" },
                        priority = 4,
                        color = cyan,
                        highlight = "DiagnosticVirtualTextHint",
                    },
                    Misc = {
                        text = { "-", "=" },
                        priority = 5,
                        color = green,
                        highlight = "Normal",
                    },
                },
                autocmd = {
                    render = {
                        "BufWinEnter",
                        "TabEnter",
                        "TermEnter",
                        "WinEnter",
                        "CmdwinLeave",
                        "TextChanged",
                        "VimResized",
                        "WinScrolled",
                    },
                    clear = {
                        "BufWinLeave",
                        "TabLeave",
                        "TermLeave",
                        "WinLeave",
                    },
                },
            })
        end,
    },
    {
        "mofiqul/vscode.nvim",
        lazy = false,
        priority = 1000,
        config = function()
            require("vscode").setup({
                transparent = true,
                italic_comments = true,
                italic_inlayhints = true,
                underline_links = true,
                disable_nvimtree_bg = true,
            })

            vim.cmd.colorscheme "vscode"
        end,
    },
}
