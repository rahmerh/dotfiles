local M = {}

_G.UserBufferline = _G.UserBufferline or {}

function _G.UserBufferline.render()
    local s = ""
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(bufnr) and vim.fn.buflisted(bufnr) == 1 then
            local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":t")
            name = name ~= "" and name or "[No Name]"
            local modified = vim.bo[bufnr].modified and " [+]" or ""
            local hl = bufnr == vim.api.nvim_get_current_buf() and "%#TabLineSel#" or "%#TabLine#"
            s = s
                .. "%"
                .. bufnr
                .. "@v:lua.UserBufferline.switch@"
                .. hl
                .. " "
                .. name
                .. modified
                .. " "
                .. "%*"
        end
    end
    return s
end

function _G.UserBufferline.switch(bufnr, _, _, _)
    vim.cmd("buffer " .. bufnr)
end

function M.setup()
    local group = vim.api.nvim_create_augroup("UserBufferline", { clear = true })

    local function apply_highlights()
        vim.api.nvim_set_hl(0, "TabLine", { fg = "#888888", bg = "NONE", bold = false })
        vim.api.nvim_set_hl(0, "TabLineSel", { fg = "#ffffff", bg = "NONE", bold = false })
        vim.api.nvim_set_hl(0, "TabLineFill", { bg = "NONE" })
    end

    vim.o.showtabline = 2
    vim.o.tabline = "%!v:lua.UserBufferline.render()"

    apply_highlights()

    vim.api.nvim_create_autocmd("ColorScheme", {
        group = group,
        callback = apply_highlights,
    })

    vim.api.nvim_create_autocmd({ "BufModifiedSet", "BufWritePost", "TextChanged", "TextChangedI" }, {
        group = group,
        callback = function()
            vim.cmd.redrawtabline()
        end,
    })
end

return M
