local M = {}

local ns = vim.api.nvim_create_namespace("user_hex_colors")
local max_lines = 10000

local function highlight_group(hex)
    local name = "UserHex" .. hex:sub(2)
    local r = tonumber(hex:sub(2, 3), 16)
    local g = tonumber(hex:sub(4, 5), 16)
    local b = tonumber(hex:sub(6, 7), 16)
    local luminance = 0.299 * r + 0.587 * g + 0.114 * b
    local fg = luminance > 140 and "#000000" or "#ffffff"

    vim.api.nvim_set_hl(0, name, { bg = hex, fg = fg })

    return name
end

local function highlight_buffer(buf)
    if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].buftype ~= "" then
        return
    end

    if vim.api.nvim_buf_line_count(buf) > max_lines then
        return
    end

    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    for row, line in ipairs(lines) do
        for col, hex in line:gmatch("()(#%x%x%x%x%x%x)%f[%X]") do
            vim.api.nvim_buf_set_extmark(buf, ns, row - 1, col - 1, {
                end_col = col - 1 + #hex,
                hl_group = highlight_group(hex),
            })
        end
    end
end

function M.setup()
    local group = vim.api.nvim_create_augroup("UserColorizer", { clear = true })

    vim.api.nvim_create_autocmd({ "BufEnter", "TextChanged", "TextChangedI" }, {
        group = group,
        callback = function(event)
            highlight_buffer(event.buf)
        end,
    })
end

return M
