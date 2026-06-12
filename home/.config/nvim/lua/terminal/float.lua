local M = {}

local function apply_style(win)
    vim.api.nvim_set_hl(0, "TerminalFloatNormal", { bg = "NONE" })
    vim.api.nvim_set_hl(0, "TerminalFloatBorder", { fg = "#FFFFFF", bg = "NONE" })

    vim.wo[win].winblend = 20
    vim.wo[win].winhighlight =
        "Normal:TerminalFloatNormal,NormalFloat:TerminalFloatNormal,FloatBorder:TerminalFloatBorder"
end

function M.window_opts(label)
    local width = math.floor(vim.o.columns * 0.8)
    local height = math.floor(vim.o.lines * 0.8)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    return {
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        style = "minimal",
        border = "rounded",
        title = label and (" " .. label .. " ") or nil,
        title_pos = "left",
    }
end

function M.open(buf, label)
    local win = vim.api.nvim_open_win(buf, true, M.window_opts(label))
    apply_style(win)
    vim.cmd("startinsert")

    return win
end

function M.hide(terminal)
    if terminal.float_win and vim.api.nvim_win_is_valid(terminal.float_win) then
        vim.api.nvim_win_hide(terminal.float_win)
        terminal.float_win = nil
    end
end

function M.close(terminal)
    if terminal.float_win and vim.api.nvim_win_is_valid(terminal.float_win) then
        vim.api.nvim_win_close(terminal.float_win, true)
    end

    if terminal.float_buf and vim.api.nvim_buf_is_valid(terminal.float_buf) then
        vim.api.nvim_buf_delete(terminal.float_buf, { force = true })
    end
end

function M.spawn(command, label, on_exit, opts)
    opts = opts or {}
    local close = opts.close or on_exit

    local float_buf = vim.api.nvim_create_buf(false, true)
    local float_win = M.open(float_buf, label)

    local job_id = vim.fn.jobstart(command, {
        term = true,
        on_exit = on_exit,
        cwd = opts.cwd,
    })

    if job_id <= 0 then
        M.close({
            float_buf = float_buf,
            float_win = float_win,
        })
        vim.notify("Failed to start terminal command: " .. vim.inspect(command), vim.log.levels.ERROR)
        return nil
    end

    vim.keymap.set("t", "<C-q>", close, { buffer = float_buf, nowait = true })

    return {
        float_buf = float_buf,
        float_win = float_win,
        job_id = job_id,
    }
end

return M
