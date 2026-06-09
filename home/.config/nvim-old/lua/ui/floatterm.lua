local M = {}

local active_terminals = {}

local function close_terminal(cmd)
    local active_terminal = active_terminals[cmd]
    if not active_terminal then
        return
    end

    if active_terminal.float_win and vim.api.nvim_win_is_valid(active_terminal.float_win) then
        vim.api.nvim_win_close(active_terminal.float_win, true)
    end

    if active_terminal.float_buf and vim.api.nvim_buf_is_valid(active_terminal.float_buf) then
        vim.api.nvim_buf_delete(active_terminal.float_buf, { force = true })
    end

    active_terminals[cmd] = nil
end

local command_overwrites = {
    yazi = {
        get_command = function()
            local tempfile = vim.fn.tempname()

            local buf_path = vim.fn.expand("%:p:h")
            if buf_path == "" then
                buf_path = vim.loop.cwd()
            end

            return { "yazi", "--chooser-file", tempfile, buf_path }, tempfile
        end,
        on_exit = function(tempfile)
            return function()
                if vim.fn.filereadable(tempfile) == 1 then
                    local files = vim.fn.readfile(tempfile)
                    if #files > 0 then
                        vim.schedule(function()
                            vim.cmd("edit " .. vim.fn.fnameescape(files[1]))
                        end)
                    end
                end
                close_terminal("yazi")
            end
        end,
    },
}

local function get_term_opts()
    local width = math.floor(vim.o.columns * 0.8)
    local height = math.floor(vim.o.lines * 0.8)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    local term_opts = {
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        style = "minimal",
        border = "none",
    }

    return term_opts
end

local function spawn_terminal_float(command, term_opts, on_exit)
    local float_buf = vim.api.nvim_create_buf(false, true)
    local float_win = vim.api.nvim_open_win(float_buf, true, term_opts)

    vim.wo[float_win].winblend = 20
    vim.wo[float_win].winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder";

    vim.fn.jobstart(command, {
        term = true,
        pty = true,
        on_exit = on_exit
    })

    vim.keymap.set("t", "<C-q>", on_exit, { buffer = float_buf, nowait = true })

    vim.cmd("startinsert")

    return {
        float_buf = float_buf,
        float_win = float_win,
    }
end

local function get_active_terminal()
    for cmd, terminal in pairs(active_terminals) do
        if terminal.float_win and vim.api.nvim_win_is_valid(terminal.float_win) then
            return cmd, terminal
        end
    end
    return nil, nil
end

function M.toggle(cmd)
    local term_opts = get_term_opts()
    local command = cmd or vim.o.shell
    local terminal = active_terminals[command]

    local active_cmd, active_terminal = get_active_terminal()

    -- This means another terminal with a different cmd is active
    if active_terminal and active_cmd ~= command then
        vim.api.nvim_win_hide(active_terminal.float_win)
        active_terminal.float_win = nil
    end

    -- This meaans a terminal with the same cmd is active
    if terminal and terminal.float_win and vim.api.nvim_win_is_valid(terminal.float_win) then
        vim.api.nvim_win_hide(terminal.float_win)
        terminal.float_win = nil

        return
    end

    -- If exists, re open hidden float
    if terminal then
        terminal.float_win = vim.api.nvim_open_win(terminal.float_buf, true, term_opts)
        vim.cmd("startinsert")

        return
    end

    -- If we're here, create a new float
    local command_to_use = command
    local on_exit = function()
        close_terminal(command)
    end

    local config = command_overwrites[command]
    if config then
        local result, tempfile = config.get_command()
        command_to_use = result
        on_exit = config.on_exit(tempfile)
    end

    terminal = spawn_terminal_float(command_to_use, term_opts, on_exit)
    active_terminals[command] = terminal
end

function M.hide_active_terminal()
    local _, terminal = get_active_terminal()

    if terminal then
        vim.api.nvim_win_hide(terminal.float_win)
    end
end

function M.print_active_terminals()
    local json_str = vim.fn.json_encode(active_terminals)
    print(json_str)
end

return M
