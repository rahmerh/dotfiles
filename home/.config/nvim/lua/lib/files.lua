local M = {}

local uv = vim.uv

function M.read(path)
    local fd = uv.fs_open(path, "r", 438)
    if not fd then
        return nil
    end

    local stat = uv.fs_fstat(fd)
    local content = stat and uv.fs_read(fd, stat.size, 0) or nil
    uv.fs_close(fd)

    return content
end

function M.find_upwards(start_dir, patterns, predicate)
    local dir = start_dir

    while dir and dir ~= "" do
        for _, pattern in ipairs(patterns) do
            local matches = vim.fn.globpath(dir, pattern, false, true)
            table.sort(matches)
            for _, match in ipairs(matches) do
                if not predicate or predicate(match, dir, pattern) then
                    return match, dir
                end
            end
        end

        local parent = vim.fn.fnamemodify(dir, ":h")
        if parent == dir then
            break
        end

        dir = parent
    end

    return nil, nil
end

return M
