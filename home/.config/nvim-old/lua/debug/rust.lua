local dap = require("dap")

local extension_path = vim.fn.stdpath("data") .. "/mason/packages/codelldb/extension/"
local adapter_path = extension_path .. "adapter/codelldb"
local liblldb_path = extension_path .. "lldb/lib/liblldb.so"

local function is_cli_project()
    local handle = io.popen("cargo metadata --no-deps --format-version 1 2>/dev/null")
    if not handle then return false end
    local output = handle:read("*a")
    handle:close()

    local ok, metadata = pcall(vim.json.decode, output)
    if not ok or not metadata.packages then return false end

    for _, pkg in ipairs(metadata.packages) do
        for _, target in ipairs(pkg.targets or {}) do
            if vim.tbl_contains(target.kind, "bin") then
                return true
            end
        end
    end

    return false
end

dap.adapters.codelldb = {
    type = "server",
    port = "${port}",
    executable = {
        command = adapter_path,
        args = {
            "--liblldb",
            liblldb_path,
            "--port",
            "${port}",
        },
        detached = true,
    },
}

dap.configurations.rust = {
    {
        name = "Launch Rust binary",
        type = "codelldb",
        request = "launch",
        program = function()
            local scan_path = vim.fn.getcwd() .. "/target/debug"
            local handle = io.popen("find " .. scan_path .. " -maxdepth 1 -type f -executable")
            if not handle then
                error("Failed to scan target/debug for binaries.")
            end

            local result = handle:read("*a")
            handle:close()

            local binaries = {}
            for line in string.gmatch(result, "[^\r\n]+") do
                table.insert(binaries, line)
            end

            if #binaries == 0 then
                error("No executable binaries found in target/debug.")
            end

            if #binaries == 1 then
                return binaries[1]
            end

            local choice = vim.fn.inputlist(
                vim.tbl_map(function(path, i)
                    return string.format("%d: %s", i, vim.fn.fnamemodify(path, ":t"))
                end, binaries)
            )

            if choice < 1 or choice > #binaries then
                error("Invalid selection.")
            end

            return binaries[choice]
        end,
        cwd = "${workspaceFolder}",
        stopOnEntry = false,
        args = function()
            if is_cli_project() then
                local input = vim.fn.input("CLI arguments: ")
                return vim.fn.split(input or "", " ")
            else
                return {}
            end
        end,
        runInTerminal = false,
    },
}
