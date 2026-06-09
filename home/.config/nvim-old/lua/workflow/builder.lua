local M = {}

local process_panel = require("ui.process-panel")

local project_types = {
    rust = { ft = "rust" },
    dotnet = { ft = { "cs", "fsharp" } },
}

local function buf_dir()
    local name = vim.api.nvim_buf_get_name(0)
    if name == "" then return nil end
    return vim.fn.fnamemodify(name, ":p:h")
end

local function start_dir()
    return buf_dir() or vim.fn.getcwd()
end

local function find_upwards(start_dir_, patterns)
    local dir = start_dir_

    while dir and dir ~= "" do
        for _, pat in ipairs(patterns) do
            local matches = vim.fn.glob(dir .. "/" .. pat, false, true)
            if #matches > 0 then
                table.sort(matches)
                return matches[1], dir
            end
        end

        local parent = vim.fn.fnamemodify(dir, ":h")
        if parent == dir then break end
        dir = parent
    end

    return nil, nil
end

local function determine_build_command(types)
    local ft = vim.bo.filetype
    local sdir = start_dir()
    if not sdir or sdir == "" then
        return nil
    end

    for kind, meta in pairs(types) do
        local fts = type(meta.ft) == "table" and meta.ft or { meta.ft }
        if not vim.tbl_contains(fts, ft) then
            goto continue
        end

        if kind == "rust" then
            local cargo_toml, root = find_upwards(sdir, { "Cargo.toml" })
            if cargo_toml then
                return {
                    command = "cargo build",
                    cwd = root,
                }
            end
        end

        if kind == "dotnet" then
            local proj, root = find_upwards(sdir, { "*.csproj", "*.fsproj" })
            if proj then
                return {
                    command = ("dotnet build %s"):format(vim.fn.fnameescape(proj)),
                    cwd = root,
                }
            end

            local sln, root2 = find_upwards(sdir, { "*.sln" })
            if sln then
                return {
                    command = ("dotnet build %s"):format(vim.fn.fnameescape(sln)),
                    cwd = root2,
                }
            end
        end

        ::continue::
    end

    return nil
end

M.build = function()
    local ft = vim.bo.filetype
    if not ft or ft == "" then
        vim.notify("Cannot build from buffer without filetype.", vim.log.levels.ERROR)
        return
    end

    local build_command = determine_build_command(project_types)

    if not build_command then
        vim.notify(
            "No build location found for filetype: " .. vim.bo.filetype,
            vim.log.levels.WARN
        )
        return
    end

    local cmd = ("cd %s && %s"):format(vim.fn.shellescape(build_command.cwd), build_command.command)
    process_panel.run_passive(cmd)
end

return M
