local M = {}

local dotnet = require("debug.dotnet")

function M.setup()
    local dap = require("dap")
    local dapui = require("dapui")

    dotnet.setup(dap)

    dapui.setup({
        layouts = {
            {
                elements = {
                    { id = "scopes", size = 0.25 },
                    { id = "breakpoints", size = 0.25 },
                    { id = "stacks", size = 0.25 },
                    { id = "watches", size = 0.25 },
                },
                size = 80,
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
        },
    })

    dap.listeners.after.event_initialized.dapui_config = dapui.open
    dap.listeners.before.event_terminated.dapui_config = dapui.close
    dap.listeners.before.event_exited.dapui_config = dapui.close

    require("persistent-breakpoints").setup({
        save_dir = vim.fn.stdpath("data") .. "/nvim_checkpoints",
        load_breakpoints_event = { "BufReadPost" },
    })

    vim.fn.sign_define("DapBreakpoint", {
        text = "●",
        texthl = "DiagnosticSignError",
    })
end

return M
