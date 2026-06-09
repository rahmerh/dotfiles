local commands = require("terminal.commands")
local float = require("terminal.float")

local M = {}

local active_terminals = {}
local shell_count = 0
local last_shell_key = nil

local function get_latest_shell_key()
    local latest_key = nil
    local latest_count = 0

    for key, terminal in pairs(active_terminals) do
        local count = key:match("^shell:(%d+)$")
        if count and terminal.float_buf and vim.api.nvim_buf_is_valid(terminal.float_buf) then
            count = tonumber(count)
            if count > latest_count then
                latest_key = key
                latest_count = count
            end
        end
    end

    return latest_key
end

local function close_terminal(key)
    local terminal = active_terminals[key]
    if not terminal then
        return
    end

    float.close(terminal)
    active_terminals[key] = nil

    if last_shell_key == key then
        last_shell_key = get_latest_shell_key()
    end

    if not last_shell_key then
        shell_count = 0
    end
end

local function get_active_terminal()
    for key, terminal in pairs(active_terminals) do
        if terminal.float_win and vim.api.nvim_win_is_valid(terminal.float_win) then
            return key, terminal
        end
    end

    return nil, nil
end

local function terminal_label(terminal)
    local state = "hidden"
    if terminal.float_win and vim.api.nvim_win_is_valid(terminal.float_win) then
        state = "visible"
    end

    return string.format("%s (%s)", terminal.label, state)
end

local function sorted_terminal_keys()
    local keys = {}

    for key, terminal in pairs(active_terminals) do
        if terminal.float_buf and vim.api.nvim_buf_is_valid(terminal.float_buf) then
            table.insert(keys, key)
        end
    end

    table.sort(keys, function(a, b)
        return active_terminals[a].label < active_terminals[b].label
    end)

    return keys
end

local function hide_active_terminal(except_key)
    local active_key, active_terminal = get_active_terminal()

    if active_terminal and active_key ~= except_key then
        float.hide(active_terminal)
    end
end

local function activate_terminal(key)
    local terminal = active_terminals[key]

    if terminal and terminal.command == vim.o.shell then
        last_shell_key = key
    end

    if terminal and terminal.float_win and vim.api.nvim_win_is_valid(terminal.float_win) then
        vim.api.nvim_set_current_win(terminal.float_win)
        vim.cmd("startinsert")
        return
    end

    if terminal then
        hide_active_terminal(key)
        terminal.float_win = float.open(terminal.float_buf, terminal.label)
    end
end

local function create_terminal(key, command, label)
    hide_active_terminal(key)

    local command_to_use, on_exit = commands.resolve(command, function()
        close_terminal(key)
    end)

    local terminal = float.spawn(command_to_use, label, on_exit)
    if not terminal then
        return
    end

    terminal.command = command
    terminal.label = label
    active_terminals[key] = terminal
end

local function run_terminal(spec)
    hide_active_terminal(spec.key)

    local terminal
    terminal = float.spawn(spec.command, spec.label, function(_, exit_code)
        if terminal then
            terminal.exited = true
            terminal.exit_code = exit_code
        end
    end, {
        cwd = spec.cwd,
        close = function()
            close_terminal(spec.key)
        end,
    })
    if not terminal then
        return
    end

    terminal.command = spec.command
    terminal.label = spec.label
    active_terminals[spec.key] = terminal
end

function M.activate(cmd)
    if cmd then
        if active_terminals[cmd] then
            activate_terminal(cmd)
        else
            create_terminal(cmd, cmd, cmd)
        end

        return
    end

    if last_shell_key and active_terminals[last_shell_key] then
        activate_terminal(last_shell_key)
    else
        M.new()
    end
end

function M.run(spec)
    vim.validate({
        spec = { spec, "table" },
    })

    vim.validate({
        command = { spec.command, "string" },
    })

    spec.key = spec.key or spec.command
    spec.label = spec.label or spec.command

    if active_terminals[spec.key] then
        activate_terminal(spec.key)
    else
        run_terminal(spec)
    end
end

function M.new()
    shell_count = shell_count + 1
    local key = "shell:" .. shell_count

    last_shell_key = key
    create_terminal(key, vim.o.shell, "shell " .. shell_count)
end

function M.cycle(direction)
    local keys = sorted_terminal_keys()
    if #keys == 0 then
        vim.notify("No active terminals")
        return
    end

    local active_key = get_active_terminal()
    local index = direction > 0 and 0 or 1

    for i, key in ipairs(keys) do
        if key == active_key then
            index = i
            break
        end
    end

    index = index + direction
    if index > #keys then
        index = 1
    elseif index < 1 then
        index = #keys
    end

    activate_terminal(keys[index])
end

function M.list()
    local terminals = {}

    for _, terminal in pairs(active_terminals) do
        if terminal.float_buf and vim.api.nvim_buf_is_valid(terminal.float_buf) then
            table.insert(terminals, terminal_label(terminal))
        end
    end

    table.sort(terminals, function(a, b)
        return a < b
    end)

    if #terminals == 0 then
        vim.notify("No active terminals")
        return
    end

    vim.notify(table.concat(terminals, "\n"), vim.log.levels.INFO, {
        title = "Active terminals",
    })
end

function M.hide_active_terminal()
    local _, terminal = get_active_terminal()

    if terminal then
        float.hide(terminal)
    end
end

return M
