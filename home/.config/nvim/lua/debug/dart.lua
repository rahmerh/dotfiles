local dap = require("dap")

dap.adapters.dart = {
    type = "executable",
    command = "flutter",
    args = { "debug_adapter" },
}

dap.configurations.dart = {
    {
        type = "dart",
        request = "launch",
        name = "Launch Flutter",
        program = "${workspaceFolder}/lib/main.dart",
        cwd = "${workspaceFolder}",
        toolArgs = { "-d", "chrome" },
    },
}
