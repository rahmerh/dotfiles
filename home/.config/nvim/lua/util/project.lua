local M = {}

local uv = vim.uv or vim.loop

local function exists(path)
    return uv.fs_stat(path) ~= nil
end

local function has_glob(dir, patterns)
    for _, pat in ipairs(patterns) do
        local m = vim.fn.globpath(dir, pat, false, true)
        if m and #m > 0 then
            return true
        end
    end
    return false
end

local function parent_dir(p)
    return vim.fn.fnamemodify(p, ":h")
end

local function markers_for_ft(ft)
    if ft == "cs" or ft == "csharp" then
        return {
            globs = { "*.sln" },
            files = { "global.json", "Directory.Build.props", "Directory.Build.targets" },
            dirs  = { ".git" },
        }
    elseif ft == "rust" then
        return {
            files = { "Cargo.toml" },
            dirs  = { ".git" },
        }
    elseif ft == "go" then
        return {
            files = { "go.mod", "go.work" },
            dirs  = { ".git" },
        }
    elseif ft == "lua" then
        return {
            files = { ".luarc.json", ".luarc.jsonc", "stylua.toml" },
            dirs  = { ".git" },
        }
    else
        -- generic
        return {
            dirs = { ".git" },
        }
    end
end

--- Find project root by walking upwards and matching filetype-specific markers.
--- @param ft string|nil filetype (e.g. "cs", "rust"). If nil, uses current buffer ft.
--- @param start_dir string|nil directory to start from. If nil, uses current buffer dir.
--- @return string project_root
M.find_project_root = function(ft, start_dir)
    ft = ft or vim.bo.filetype
    local path = start_dir or vim.fn.expand("%:p:h")

    if not path or path == "" then
        error("Cannot determine project root: no buffer path")
    end

    local markers = markers_for_ft(ft)

    while true do
        -- 1) glob markers (like *.sln)
        if markers.globs and has_glob(path, markers.globs) then
            return path
        end

        -- 2) file markers
        if markers.files then
            for _, f in ipairs(markers.files) do
                if exists(path .. "/" .. f) then
                    return path
                end
            end
        end

        -- 3) dir markers
        if markers.dirs then
            for _, d in ipairs(markers.dirs) do
                if exists(path .. "/" .. d) then
                    return path
                end
            end
        end

        local parent = parent_dir(path)
        if parent == path then
            break
        end
        path = parent
    end

    -- last fallback: just use start dir so callers can still run *something*
    return start_dir or vim.fn.expand("%:p:h")
end

M.find_files_upwards = function(root, filenames)
    local found = {}

    local function scan(dir)
        local fd = uv.fs_scandir(dir)
        if not fd then return end

        while true do
            local name, typ = uv.fs_scandir_next(fd)
            if not name then break end

            local full = dir .. "/" .. name

            if typ == "file" then
                for _, wanted in ipairs(filenames) do
                    if name == wanted then
                        table.insert(found, full)
                    end
                end
            elseif typ == "directory" then
                -- hard stop: avoid vendor trash
                if name ~= ".git" and name ~= "node_modules" and name ~= "bin" and name ~= "obj" then
                    scan(full)
                end
            end
        end
    end

    scan(root)
    return found
end

return M
