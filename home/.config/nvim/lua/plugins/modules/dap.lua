return {
    {
        "mfussenegger/nvim-dap",
        keys = {
            { "<F5>",    "<cmd>DapContinue<cr>",        desc = "Start Debugger" },
            { "<F10>",   "<cmd>DapStepOver<cr>",        desc = "Step Over" },
            { "<F11>",   "<cmd>DapStepInto<cr>",        desc = "Step Into" },
            { "<S-F11>", "<cmd>DapStepOut<cr>",         desc = "Step Out" },
            { "<S-F5>",  "<cmd>DapTerminate<cr>",       desc = "Terminate" },
            { "<C-b>",   "<cmd>PBToggleBreakpoint<cr>", desc = "Toggle Breakpoint" },
            { "dt",      "<cmd>DapToggleRepl<cr>",      desc = "Toggle REPL" },
        },
        config = function()
            require("debug.bash")
            require("debug.rust")

            local dap, dapui = require("dap"), require("dapui")
            dap.listeners.before.attach.dapui_config = function()
                dapui.open()
            end
            dap.listeners.before.launch.dapui_config = function()
                dapui.open()
            end
            dap.listeners.before.event_terminated.dapui_config = function()
                dapui.close()
            end
            dap.listeners.before.event_exited.dapui_config = function()
                dapui.close()
            end
        end,
    },
    {
        "rcarriga/nvim-dap-ui",
        lazy = true,
        dependencies = {
            "mfussenegger/nvim-dap",
            "nvim-neotest/nvim-nio",
        },
        config = function()
            local dapui = require("dapui")
            local dap = require("dap")
            local icons = require("ui.icons")

            dapui.setup({
                layouts = {
                    {
                        elements = {
                            { id = "scopes",      size = 0.25 },
                            { id = "breakpoints", size = 0.25 },
                            { id = "stacks",      size = 0.25 },
                            { id = "watches",     size = 0.25 },
                        },
                        size = 40,
                        position = "right",
                    },
                    {
                        elements = { "repl", "console" },
                        size = 10,
                        position = "bottom",
                    },
                },
                controls = {
                    enabled = true,
                    element = "repl",
                    icons = icons.debugging.controls,
                },
            })

            dap.listeners.after.event_initialized["dapui_config"] = function()
                dapui.open()
            end
            dap.listeners.before.event_terminated["dapui_config"] = function()
                dapui.close()
            end
            dap.listeners.before.event_exited["dapui_config"] = function()
                dapui.close()
            end
        end,
    },
    {
        "Weissle/persistent-breakpoints.nvim",
        keys = {
            { "<C-b>", "<cmd>PBToggleBreakpoint<cr>", desc = "Toggle Persistent Breakpoint" },
        },
        config = function()
            local icons = require("ui.icons")

            require("persistent-breakpoints").setup({
                save_dir = vim.fn.stdpath("data") .. "/nvim_checkpoints",
                load_breakpoints_event = { "BufReadPost" },
            })

            vim.fn.sign_define("DapBreakpoint", {
                text = icons.debugging.Breakpoint,
                texthl = "DiagnosticSignError",
                linehl = "",
                numhl = "",
            })
        end,
    },
}
