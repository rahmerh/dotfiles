local files = require("lib.files")

local M = {}

local uv = vim.uv

local project_patterns = { "*.csproj", "*.fsproj", "*.vbproj" }
local solution_patterns = { "*.sln", "*.slnx" }

local function property(content, name)
    return content:match("<" .. name .. "%s*>%s*([^<]-)%s*</" .. name .. ">")
end

function M.find_project(start_dir)
    return files.find_upwards(start_dir, project_patterns)
end

function M.find_solution(start_dir)
    return files.find_upwards(start_dir, solution_patterns)
end

function M.solution_projects(solution)
    local content = files.read(solution)
    if not content then
        error("Could not read solution: " .. solution, 0)
    end

    local root = vim.fn.fnamemodify(solution, ":p:h")
    local projects = {}

    local function add(path)
        if path then
            table.insert(projects, vim.fs.normalize(root .. "/" .. path:gsub("\\", "/")))
        end
    end

    if vim.fn.fnamemodify(solution, ":e") == "slnx" then
        for path in content:gmatch('<Project%s+[^>]-Path="([^"]+%.[cfv]sproj)"') do
            add(path)
        end
    else
        for line in content:gmatch("[^\r\n]+") do
            add(line:match('Project%("[^"]+"%) = "[^"]+", "([^"]+%.[cfv]sproj)", "[^"]+"'))
        end
    end

    table.sort(projects)
    return projects
end

function M.project_metadata(path)
    local content = files.read(path)
    if not content then
        return nil
    end

    local dir = vim.fn.fnamemodify(path, ":p:h")
    local sdk = content:match('<Project[^>]-Sdk="([^"]+)"') or ""
    local target_framework = property(content, "TargetFramework")
    local target_frameworks = property(content, "TargetFrameworks")

    return {
        path = path,
        sdk = sdk,
        output_type = property(content, "OutputType") or "",
        target_framework = target_framework or (target_frameworks and target_frameworks:match("^[^;]+")),
        assembly_name = property(content, "AssemblyName") or vim.fn.fnamemodify(path, ":t:r"),
        has_program = uv.fs_stat(dir .. "/Program.cs") ~= nil,
        is_test_project = property(content, "IsTestProject") == "true"
            or content:match('PackageReference%s+Include="Microsoft%.NET%.Test%.Sdk"') ~= nil,
    }
end

function M.is_debuggable_project(metadata)
    if not metadata or metadata.is_test_project then
        return false
    end

    local output_type = metadata.output_type:lower()
    if output_type == "exe" or output_type == "winexe" then
        return true
    end

    return metadata.has_program
        or metadata.sdk:match("Microsoft%.NET%.Sdk%.Web") ~= nil
        or metadata.sdk:match("Microsoft%.NET%.Sdk%.Worker") ~= nil
end

function M.dll_for_project(metadata)
    if not metadata then
        error("Could not read project file", 0)
    end

    if not metadata.target_framework then
        error("Could not determine target framework for " .. metadata.path, 0)
    end

    local dll = table.concat({
        vim.fn.fnamemodify(metadata.path, ":p:h"),
        "bin",
        "Debug",
        metadata.target_framework,
        metadata.assembly_name .. ".dll",
    }, "/")

    if not uv.fs_stat(dll) then
        error("Debug target does not exist, build the project first: " .. dll, 0)
    end

    return dll
end

return M
