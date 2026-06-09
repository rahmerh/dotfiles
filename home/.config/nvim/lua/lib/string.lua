local M = {}

function M.truncate(value, max_width)
    if #value <= max_width then
        return value
    end

    return value:sub(1, max_width - 3) .. "..."
end

return M
