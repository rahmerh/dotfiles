return {
    {
        "neovim/nvim-lspconfig",
        event = { "BufReadPre", "BufNewFile" },
        dependencies = {
            "williamboman/mason-lspconfig.nvim",
        },
        config = function()
            vim.lsp.enable('lua_ls')
            vim.lsp.enable('bashls')
            vim.lsp.enable('fish_lsp')
            vim.lsp.enable("tombi")
            vim.lsp.enable('gopls')
            vim.lsp.enable('html')
            vim.lsp.enable('dockerls')
            vim.lsp.enable('jsonls')
            vim.lsp.enable('buf_ls')
            vim.lsp.enable('yamlls')
            vim.lsp.enable('cspell_ls')
            vim.lsp.enable('postgres_lsp')
        end
    },
    {
        "GustavEikaas/easy-dotnet.nvim",
        dependencies = { "nvim-lua/plenary.nvim", 'nvim-telescope/telescope.nvim', },
        config = function()
            require("easy-dotnet").setup({

                notifications = {
                    handler = false
                },
            })
        end
    },
    {
        "williamboman/mason.nvim",
        cmd = { "Mason", "MasonInstall", "MasonUpdate", "MasonLog" },
        opts = {
            ui = {
                icons = {
                    package_installed = "✓",
                    package_pending = "➜",
                    package_uninstalled = "✗"
                }
            },
            log_level = vim.log.levels.INFO,
            max_concurrent_installers = 4,
        }
    },
    {
        "mason-org/mason-lspconfig.nvim",
        event = { "BufReadPre", "BufNewFile" },
        opts = {
            automatic_enable = false
        },
        dependencies = {
            "mason-org/mason.nvim",
            "neovim/nvim-lspconfig",
        },
    },
    {
        'owallb/mason-auto-install.nvim',
        event = { "BufReadPre", "BufNewFile" },
        opts = {
            packages = {
                -- LSP
                "rust-analyzer",
                "lua-language-server",
                "bash-language-server",
                "fish-lsp",
                "tombi",
                "gopls",
                "html-lsp",
                "dockerfile-language-server",
                "json-lsp",
                "buf",
                "yaml-language-server",
                "cspell-lsp",
                "postgres-language-server",
                -- DAP
                "netcoredbg"
            }
        },
        dependencies = {
            'williamboman/mason.nvim',
            'neovim/nvim-lspconfig',
        },
    },
    {
        "lewis6991/hover.nvim",
        keys = {
            { "K", function() require("hover").hover() end, desc = "Hover docs" },
        },
        config = function()
            require("hover").setup {
                providers = {
                    'hover.providers.lsp',
                },
                preview_opts = { border = "none" },
                title = true,
            }
        end,
    },
    {
        'mrcjkb/rustaceanvim',
        version = '^6',
        ft = "rust",
        init = function()
            local extension_path = vim.fn.stdpath("data") .. "/mason/packages/codelldb/extension/"
            local codelldb_path  = extension_path .. "adapter/codelldb"
            local liblldb_path   = extension_path .. "lldb/lib/liblldb.so"

            local cfg            = require("rustaceanvim.config")

            vim.g.rustaceanvim   = {
                dap = {
                    adapter = cfg.get_codelldb_adapter(codelldb_path, liblldb_path),
                },
            }
        end,
    },
    {
        'nvim-flutter/flutter-tools.nvim',
        lazy = false,
        dependencies = {
            'nvim-lua/plenary.nvim',
        },
        keys = {
            { "<C-f>l", "<cmd>FlutterLogToggle<cr>", desc = "Toggle flutter log buf" },
        },
        config = function()
            require("flutter-tools").setup({
                fvm = true
            })
        end,
    },
    {
        "chrisgrieser/nvim-lsp-endhints",
        event = "LspAttach",
        opts = {}, -- required, even if empty
        config = function()
            require("lsp-endhints").setup({
                autoEnableHints = false
            })
        end
    },
}
