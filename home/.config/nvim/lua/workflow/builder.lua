local M = {}

local process_panel = require("ui.process-panel")

local project_types = {
    rust = {
        ft = "rust",
    },
    dotnet = {
        ft = { "cs", "fsharp" },
    },
}

local function buf_dir()
    local name = vim.api.nvim_buf_get_name(0)
    if name == "" then return nil end
    return vim.fn.fnamemodify(name, ":p:h")
end

local function find_upwards(start_dir, patterns)
    local dir = start_dir

    while dir do
        for _, pat in ipairs(patterns) do
            local matches = vim.fn.glob(dir .. "/" .. pat, false, true)
            if #matches > 0 then
                table.sort(matches)
                return matches[1]
            end
        end

        local parent = vim.fn.fnamemodify(dir, ":h")
        if parent == dir then break end
        dir = parent
    end
end

local function determine_build_command(types)
    local ft = vim.bo.filetype
    local start_dir = buf_dir()
    if not start_dir then
        return nil
    end

    for kind, meta in pairs(types) do
        local fts = type(meta.ft) == "table" and meta.ft or { meta.ft }
        if not vim.tbl_contains(fts, ft) then
            goto continue
        end

        if kind == "rust" then
            local cargo, dir = find_upwards(start_dir, { "Cargo.toml" })
            if cargo then
                return {
                    command = "cargo build",
                    cwd = dir,
                }
            end
        end

        if kind == "dotnet" then
            local csproj = find_upwards(start_dir, { "*.csproj", "*.fsproj" })
            if csproj then
                return {
                    command = string.format("dotnet build %s", csproj),
                    cwd = "."
                }
            end

            local sln = find_upwards(start_dir, { "*.sln" })
            if sln then
                return {
                    command = string.format("dotnet build %s", sln),
                    cwd = "."
                }
            end
        end

        ::continue::
    end
end

local active_build_win = nil

M.build = function()
    local build_command = determine_build_command(project_types)

    if not build_command then
        vim.notify(
            "No build location found for filetype: " .. vim.bo.filetype,
            vim.log.levels.WARN
        )
        return nil
    end

    process_panel.run_passive(string.format("cd %s && %s", build_command.cwd, build_command.command))
end

M.close_build_log = function()
    if active_build_win and vim.api.nvim_win_is_valid(active_build_win) then
        vim.api.nvim_win_close(active_build_win, true)
        active_build_win = nil
    end
end

return M
