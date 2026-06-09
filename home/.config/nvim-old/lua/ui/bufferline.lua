local M = {}

function _G.MyBufferTabline()
    local s = ""
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(bufnr) and vim.fn.buflisted(bufnr) == 1 then
            local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":t")
            name = name ~= "" and name or "[No Name]"
            if vim.bo[bufnr].modified then
                name = name .. " [+]"
            end
            local hl = bufnr == vim.api.nvim_get_current_buf() and "%#TabLineSel#" or "%#TabLine#"
            s = s .. "%" .. bufnr .. "@v:lua.SwitchBuffer@" .. hl .. " " .. name .. " " .. "%*"
        end
    end
    return s
end

function _G.SwitchBuffer(bufnr, _, _, _)
    vim.cmd("buffer " .. bufnr)
end

function M.setup()
    local function apply_highlights()
        vim.api.nvim_set_hl(0, "TabLine", { fg = "#888888", bg = "NONE", bold = false })
        vim.api.nvim_set_hl(0, "TabLineSel", { fg = "#ffffff", bg = "NONE", bold = false })
        vim.api.nvim_set_hl(0, "TabLineFill", { bg = "NONE" })
    end

    vim.o.showtabline = 2
    vim.o.tabline = "%!v:lua.MyBufferTabline()"

    apply_highlights()

    vim.api.nvim_create_autocmd("ColorScheme", {
        callback = apply_highlights,
    })
end

return M
