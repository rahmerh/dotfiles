local dotnet = require("workflow.dotnet")
local project = require("workflow.project")

local M = {}

local function current_project()
    local project_path = dotnet.find_project(project.start_dir())
    if not project_path then
        error("No solution or project found above current buffer", 0)
    end

    return dotnet.project_metadata(project_path)
end

local function project_label(metadata)
    return vim.fn.fnamemodify(metadata.path, ":~:.")
end

local function select_project(candidates)
    if #candidates == 0 then
        error("No debuggable projects found in solution", 0)
    end

    if #candidates == 1 then
        return candidates[1]
    end

    local selection = require("dap.ui").pick_one(candidates, "Debug project", project_label)
    if not selection then
        error("Debug project selection cancelled", 0)
    end

    return selection
end

local function environment_label(environment)
    return environment
end

local function project_environments(cwd)
    local seen = {}
    local environments = {}

    local function add(environment)
        if environment and environment ~= "" and not seen[environment] then
            seen[environment] = true
            table.insert(environments, environment)
        end
    end

    if vim.fn.filereadable(cwd .. "/appsettings.json") == 1 then
        add("Production")
    end

    local files = vim.fn.globpath(cwd, "appsettings.*.json", false, true)
    table.sort(files)

    for _, file in ipairs(files) do
        add(vim.fn.fnamemodify(file, ":t"):match("^appsettings%.(.+)%.json$"))
    end

    return environments
end

local function select_environment(cwd)
    local environments = project_environments(cwd)
    if #environments == 0 then
        return nil
    end

    if #environments == 1 then
        return environments[1]
    end

    local selection = require("dap.ui").pick_one(environments, "Debug environment", environment_label)
    if not selection then
        error("Debug environment selection cancelled", 0)
    end

    return selection
end

local function environment_variables(environment)
    if not environment then
        return nil
    end

    return {
        ASPNETCORE_ENVIRONMENT = environment,
        DOTNET_ENVIRONMENT = environment,
    }
end

local function debug_project()
    local sln = dotnet.find_solution(project.start_dir())
    if not sln then
        return current_project()
    end

    local candidates = {}
    for _, path in ipairs(dotnet.solution_projects(sln)) do
        local metadata = dotnet.project_metadata(path)
        if dotnet.is_debuggable_project(metadata) then
            table.insert(candidates, metadata)
        end
    end

    return select_project(candidates)
end

local function debug_configuration()
    local metadata = debug_project()
    local cwd = vim.fn.fnamemodify(metadata.path, ":p:h")
    local environment = select_environment(cwd)

    return {
        type = "coreclr",
        name = "Launch .NET",
        request = "launch",
        program = dotnet.dll_for_project(metadata),
        cwd = cwd,
        env = environment_variables(environment),
    }
end

function M.configurations()
    return {
        setmetatable({
            type = "coreclr",
            name = "Launch .NET",
            request = "launch",
        }, {
            __call = debug_configuration,
        }),
    }
end

function M.setup(dap)
    dap.adapters.coreclr = {
        type = "executable",
        command = "netcoredbg",
        args = { "--interpreter=vscode" },
    }

    dap.adapters.netcoredbg = dap.adapters.coreclr

    dap.configurations.cs = M.configurations()
    dap.configurations.fsharp = dap.configurations.cs
end

return M
