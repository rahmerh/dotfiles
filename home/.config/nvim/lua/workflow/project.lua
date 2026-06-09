local M = {}

local uv = vim.uv

local function buffer_dir()
    local name = vim.api.nvim_buf_get_name(0)
    if name == "" then
        return nil
    end

    return vim.fn.fnamemodify(name, ":p:h")
end

function M.start_dir()
    return buffer_dir() or vim.fn.getcwd()
end

function M.find_root(start_dir)
    local path = start_dir or M.start_dir()

    if not path or path == "" then
        return nil
    end

    while true do
        if uv.fs_stat(path .. "/.git") then
            return path
        end

        local parent = vim.fn.fnamemodify(path, ":h")
        if parent == path then
            return start_dir or M.start_dir()
        end

        path = parent
    end
end

function M.nvim_dir(root)
    return root .. "/.nvim"
end

return M
