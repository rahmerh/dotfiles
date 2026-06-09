return {
    {
        "nvim-telescope/telescope.nvim",
        cmd = "Telescope",
        keys = {
            { "<leader>f", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
            { "<leader>g", "<cmd>Telescope live_grep<cr>",  desc = "Live Grep" },
            {
                "<leader>n",
                function()
                    require("telescope.builtin").find_files({ no_ignore = true })
                end,
                desc = "Find Files (include gitignored)",
            },
        },
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
        config = function()
            local actions = require("telescope.actions")

            require("telescope").setup({
                defaults = {
                    prompt_prefix = " ",
                    selection_caret = " ",
                    entry_prefix = " ",
                    layout_strategy = "horizontal",
                    layout_config = {
                        horizontal = {
                            prompt_position = "top",
                            preview_width = 0.5,
                            results_width = 0.5,
                        },
                        width = 0.85,
                        height = 0.60,
                        preview_cutoff = 120,
                    },
                    sorting_strategy = "ascending",
                    winblend = 20,
                    border = true,
                    borderchars = { " ", " ", " ", " ", " ", " ", " ", " " },
                    path_display = { "truncate" },
                    color_devicons = false,

                    mappings = {
                        i = {
                            ["<C-c>"] = actions.close,
                            ["<Esc>"] = actions.close,
                        },
                        n = {
                            ["<Esc>"] = actions.close,
                        },
                    },
                },
                pickers = {
                    find_files = {
                        hidden = true,
                    },
                    live_grep = {
                        hidden = true,
                    },
                },
            })
        end,
    }

}
