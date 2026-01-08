local dap = require("dap")

local function determine_dll_to_debug()
    local root = vim.fn.getcwd()

    local globs = {
        root .. "/**/bin/Debug/**/net*/**/*.dll",
        root .. "/**/bin/Debug/**/**/*.dll",
        root .. "/**/bin/Release/**/net*/**/*.dll",
        root .. "/**/bin/Release/**/**/*.dll",
    }

    local candidates = {}
    local seen = {}

    local function add(path)
        if path == "" then return end
        local p = path:gsub("\\", "/")

        if p:match("/ref/") then return end
        if p:match("%.Views%.dll$") then return end
        if p:match("%.resources%.dll$") then return end

        if not seen[p] then
            seen[p] = true
            table.insert(candidates, path)
        end
    end

    for _, g in ipairs(globs) do
        for _, p in ipairs(vim.fn.glob(g, true, true)) do
            add(p)
        end
    end

    if #candidates == 0 then
        error("No dlls found in bin folder, did you build the project?", 0)
    end

    if #candidates == 1 then
        return candidates[1]
    end

    local choice = nil;
    vim.ui.select(
        candidates,
        { prompt = "Select dll to debug" },
        function(item)
            choice = item
        end
    )

    if choice == nil then
        error("User cancelled dll selection", 0)
    end

    return candidates[choice]
end

dap.adapters.coreclr = {
    type = "executable",
    command = "netcoredbg",
    args = { "--interpreter=vscode" },
}

dap.configurations.cs = {
    {
        type = "coreclr",
        name = "Launch .NET",
        request = "launch",
        program = determine_dll_to_debug,
    },
}

dap.configurations.fsharp = dap.configurations.cs
