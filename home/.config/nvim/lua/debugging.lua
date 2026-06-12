local M = {}

local dotnet = require("debug.dotnet")
local breakpoints = require("debug.breakpoints")

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

    breakpoints.setup()

    vim.fn.sign_define("DapBreakpoint", {
        text = "●",
        texthl = "DiagnosticSignError",
    })
end

return M
