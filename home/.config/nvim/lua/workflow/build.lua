local processes = require("workflow.processes")
local project = require("workflow.project")
local files = require("lib.files")

local M = {}

local function start_build(spec)
    local id = processes.start({
        name = spec.name,
        command = spec.command,
        cwd = spec.cwd,
    })

    if id then
        processes.open_logs(id)
    end
end

local builders = {
    {
        project = function(start_dir)
            local path, cwd = files.find_upwards(start_dir, { "*.csproj", "*.fsproj", "*.vbproj" })
            if path then
                return {
                    name = "build " .. vim.fn.fnamemodify(path, ":t"),
                    command = "dotnet build " .. vim.fn.shellescape(path),
                    cwd = cwd,
                }
            end
        end,

        workspace = function(start_dir)
            local path, cwd = files.find_upwards(start_dir, { "*.sln", "*.slnx" })
            if path then
                return {
                    name = "build " .. vim.fn.fnamemodify(path, ":t"),
                    command = "dotnet build " .. vim.fn.shellescape(path),
                    cwd = cwd,
                }
            end
        end,
    },
    {
        project = function(start_dir)
            local path, cwd = files.find_upwards(start_dir, { "go.mod" })
            if path then
                return {
                    name = "build " .. vim.fn.fnamemodify(cwd, ":t"),
                    command = "go build ./...",
                    cwd = cwd,
                }
            end
        end,

        workspace = function(start_dir)
            local path, cwd = files.find_upwards(start_dir, { "go.work" })
            if path then
                return {
                    name = "build " .. vim.fn.fnamemodify(cwd, ":t"),
                    command = "go build ./...",
                    cwd = cwd,
                }
            end
        end,
    },
    {
        project = function(start_dir)
            local path, cwd = files.find_upwards(start_dir, { "Cargo.toml" })
            if path then
                return {
                    name = "build " .. vim.fn.fnamemodify(cwd, ":t"),
                    command = "cargo build",
                    cwd = cwd,
                }
            end
        end,

        workspace = function(start_dir)
            local path, cwd = files.find_upwards(start_dir, { "Cargo.toml" }, function(manifest)
                local content = files.read(manifest)
                return content and content:match("%f[%[]%[workspace%]")
            end)
            if path then
                return {
                    name = "build " .. vim.fn.fnamemodify(cwd, ":t"),
                    command = "cargo build --workspace",
                    cwd = cwd,
                }
            end
        end,
    },
}

local function detect_build(kind)
    local start_dir = project.start_dir()

    for _, builder in ipairs(builders) do
        local build = builder[kind] and builder[kind](start_dir)
        if build then
            return build
        end
    end

    if kind == "workspace" then
        return detect_build("project")
    end

    return nil
end

local function build(kind)
    local spec = detect_build(kind)
    if not spec then
        vim.notify("No build target found above current buffer", vim.log.levels.WARN)
        return
    end

    start_build(spec)
end

function M.project()
    build("project")
end

function M.workspace()
    build("workspace")
end

return M
