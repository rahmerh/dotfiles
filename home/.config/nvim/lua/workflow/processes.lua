local M = {}

local string_util = require("lib.string")

local ns = vim.api.nvim_create_namespace("workflow_processes")
local processes = {}
local update_log_buffer

local highlights = {
    running = "WorkflowProcessRunning",
    completed = "WorkflowProcessCompleted",
    failed = "WorkflowProcessFailed",
}

local function setup_highlights()
    vim.api.nvim_set_hl(0, highlights.running, { fg = "#4EC9B0" })
    vim.api.nvim_set_hl(0, highlights.completed, { fg = "#858585" })
    vim.api.nvim_set_hl(0, highlights.failed, { fg = "#F44747" })
    vim.api.nvim_set_hl(0, "WorkflowProcessBox", { bg = "NONE" })
    vim.api.nvim_set_hl(0, "WorkflowProcessBorder", { fg = "#3C3C3C", bg = "NONE" })
end

local function append_log(process, stream, data)
    if not data then
        return
    end

    for _, line in ipairs(data) do
        if line ~= "" then
            table.insert(process.logs, {
                stream = stream,
                line = line,
            })
        end
    end

    if process.log_buf and vim.api.nvim_buf_is_valid(process.log_buf) then
        update_log_buffer(process)
    end
end

local function status_highlight(process)
    if process.status == "running" then
        return highlights.running
    end

    if process.exit_code == 0 then
        return highlights.completed
    end

    return highlights.failed
end

local function ordered_processes()
    local ordered = {}

    for _, process in pairs(processes) do
        table.insert(ordered, process)
    end

    table.sort(ordered, function(a, b)
        return a.id < b.id
    end)

    return ordered
end

local function next_process_id()
    local id = 1

    while processes[id] do
        id = id + 1
    end

    return id
end

local function ensure_window(process, row, col, width)
    if not process.buf or not vim.api.nvim_buf_is_valid(process.buf) then
        process.buf = vim.api.nvim_create_buf(false, true)
        vim.bo[process.buf].bufhidden = "hide"
        vim.bo[process.buf].buftype = "nofile"
        vim.bo[process.buf].swapfile = false
    end

    if process.win and vim.api.nvim_win_is_valid(process.win) then
        vim.api.nvim_win_set_config(process.win, {
            relative = "editor",
            row = row,
            col = col,
            width = width,
            height = 1,
            zindex = 60,
        })

        return
    end

    process.win = vim.api.nvim_open_win(process.buf, false, {
        relative = "editor",
        row = row,
        col = col,
        width = width,
        height = 1,
        style = "minimal",
        border = "rounded",
        focusable = false,
        noautocmd = true,
        zindex = 60,
    })

    vim.wo[process.win].winblend = 10
    vim.wo[process.win].winhighlight = "Normal:WorkflowProcessBox,FloatBorder:WorkflowProcessBorder"
end

local function render_process(process, row, col, width)
    ensure_window(process, row, col, width)

    local id = tostring(process.id)
    local name_width = math.max(1, width - #id - 4)
    local name = string_util.truncate(process.name, name_width)
    local padding = string.rep(" ", math.max(1, width - #name - #id - 3))
    local line = "● " .. name .. padding .. id

    vim.bo[process.buf].modifiable = true
    vim.api.nvim_buf_set_lines(process.buf, 0, -1, false, { line })
    vim.api.nvim_buf_clear_namespace(process.buf, ns, 0, -1)
    vim.api.nvim_buf_set_extmark(process.buf, ns, 0, 0, {
        end_col = 3,
        hl_group = status_highlight(process),
    })
    vim.bo[process.buf].modifiable = false
end

local function render()
    setup_highlights()

    local width = math.min(42, math.max(24, math.floor(vim.o.columns * 0.28)))
    local col = math.max(0, vim.o.columns - width - 2)
    local row = 1

    for _, process in ipairs(ordered_processes()) do
        render_process(process, row, col, width)
        row = row + 3
    end
end

local function mark_failed_start(process)
    process.status = "exited"
    process.exit_code = 1
    table.insert(process.logs, {
        stream = "stderr",
        line = "Failed to start process: " .. process.command,
    })
    render()
end

local function close_window(win)
    if win and vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
    end
end

local function delete_buffer(buf)
    if buf and vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_buf_delete(buf, { force = true })
    end
end

local function clear_process(id)
    local process = processes[id]
    if not process then
        return
    end

    close_window(process.win)
    close_window(process.log_win)
    delete_buffer(process.buf)
    delete_buffer(process.log_buf)

    processes[id] = nil
    render()
end

local function focus_return_window(process)
    if process.log_origin_win and vim.api.nvim_win_is_valid(process.log_origin_win) then
        vim.api.nvim_set_current_win(process.log_origin_win)
    end
end

local function configure_log_window(win)
    vim.wo[win].wrap = true
    vim.wo[win].linebreak = true
    vim.wo[win].breakindent = true
    vim.wo[win].breakindentopt = "shift:2"
    vim.wo[win].showbreak = "-> "

    vim.wo[win].scrolloff = 0
    vim.wo[win].sidescrolloff = 0
    vim.wo[win].number = false
    vim.wo[win].relativenumber = false
    vim.wo[win].signcolumn = "no"
    vim.wo[win].cursorline = false
    vim.wo[win].foldcolumn = "0"
    vim.wo[win].spell = false
    vim.wo[win].list = false
    vim.wo[win].conceallevel = 0
end

local function dock_log_window(process)
    if not process.log_win or not vim.api.nvim_win_is_valid(process.log_win) then
        return
    end

    vim.api.nvim_win_set_config(process.log_win, {
        relative = "editor",
        anchor = "NE",
        width = math.floor(vim.o.columns * 0.2),
        height = math.floor(vim.o.lines * 0.9),
        row = 1,
        col = vim.o.columns,
        style = "minimal",
        border = "rounded",
        focusable = true,
        zindex = 50,
        title = (" '%s' logs "):format(process.name),
        title_pos = "left",
    })

    configure_log_window(process.log_win)
    process.log_docked = true
    focus_return_window(process)
end

local function expand_log_window(process)
    if not process.log_win or not vim.api.nvim_win_is_valid(process.log_win) then
        return
    end

    local width = math.floor(vim.o.columns * 0.8)
    local height = math.floor(vim.o.lines * 0.7)

    vim.api.nvim_win_set_config(process.log_win, {
        relative = "editor",
        width = width,
        height = height,
        row = math.floor((vim.o.lines - height) / 2),
        col = math.floor((vim.o.columns - width) / 2),
        style = "minimal",
        border = "rounded",
        title = (" '%s' logs "):format(process.name),
        title_pos = "left",
        focusable = true,
        zindex = 50,
    })

    configure_log_window(process.log_win)
    process.log_docked = false
end

update_log_buffer = function(process)
    local lines = {}

    for _, entry in ipairs(process.logs) do
        if entry.stream == "stderr" then
            table.insert(lines, "[stderr] " .. entry.line)
        else
            table.insert(lines, entry.line)
        end
    end

    if #lines == 0 then
        lines = { "(no output yet)" }
    end

    vim.bo[process.log_buf].modifiable = true
    vim.api.nvim_buf_set_lines(process.log_buf, 0, -1, false, lines)
    vim.bo[process.log_buf].modifiable = false

    if process.log_win and vim.api.nvim_win_is_valid(process.log_win) then
        vim.api.nvim_win_set_cursor(process.log_win, { #lines, 0 })
    end
end

function M.start(spec)
    vim.validate({
        spec = { spec, "table" },
        command = { spec.command, "string" },
        name = { spec.name, "string" },
    })

    local process = {
        id = next_process_id(),
        name = spec.name,
        command = spec.command,
        cwd = spec.cwd,
        status = "running",
        exit_code = nil,
        logs = {},
        started_at = os.time(),
    }

    processes[process.id] = process
    render()

    local job_id = vim.fn.jobstart(process.command, {
        cwd = process.cwd,
        stdout_buffered = false,
        stderr_buffered = false,
        on_stdout = function(_, data)
            append_log(process, "stdout", data)
        end,
        on_stderr = function(_, data)
            append_log(process, "stderr", data)
        end,
        on_exit = function(_, exit_code)
            process.status = "exited"
            process.exit_code = exit_code
            if exit_code == 0 then
                table.insert(process.logs, {
                    stream = "stdout",
                    line = "Process exited successfully",
                })
            end
            if process.log_buf and vim.api.nvim_buf_is_valid(process.log_buf) then
                update_log_buffer(process)
            end
            vim.schedule(render)
        end,
    })

    if job_id <= 0 then
        mark_failed_start(process)
        return nil
    end

    process.job_id = job_id

    return process.id
end

function M.kill(id)
    local process = processes[id]
    if not process then
        vim.notify("No process with id " .. id, vim.log.levels.WARN)
        return
    end

    if process.status ~= "running" or not process.job_id then
        vim.notify("Process " .. id .. " is not running", vim.log.levels.WARN)
        return
    end

    process.status = "exited"
    process.exit_code = 143
    table.insert(process.logs, {
        stream = "stderr",
        line = "Process killed",
    })
    render()
    vim.fn.jobstop(process.job_id)
end

function M.clear_exited()
    for id, process in pairs(processes) do
        if process.status ~= "running" then
            clear_process(id)
        end
    end
end

function M.move(id, target_id)
    target_id = tonumber(target_id)

    if not target_id or target_id < 1 then
        vim.notify("Invalid target process id", vim.log.levels.WARN)
        return
    end

    local process = processes[id]
    if not process then
        vim.notify("No process with id " .. id, vim.log.levels.WARN)
        return
    end

    if id == target_id then
        return
    end

    local target_process = processes[target_id]

    processes[id] = target_process
    processes[target_id] = process
    process.id = target_id

    if target_process then
        target_process.id = id
    end

    render()
end

function M.prompt_move(id)
    vim.ui.input({ prompt = ("Move process %d to id: "):format(id) }, function(target_id)
        if not target_id or target_id == "" then
            return
        end

        M.move(id, target_id)
    end)
end

function M.open_logs(id)
    local process = processes[id]
    if not process then
        vim.notify("No process with id " .. id, vim.log.levels.WARN)
        return
    end

    if not process.log_buf or not vim.api.nvim_buf_is_valid(process.log_buf) then
        process.log_buf = vim.api.nvim_create_buf(false, true)
        vim.bo[process.log_buf].bufhidden = "hide"
        vim.bo[process.log_buf].buftype = "nofile"
        vim.bo[process.log_buf].filetype = "log"
        vim.bo[process.log_buf].swapfile = false
    end

    local current_win = vim.api.nvim_get_current_win()
    if not (process.log_win and current_win == process.log_win) then
        process.log_origin_win = current_win
    end

    update_log_buffer(process)

    if process.log_win and vim.api.nvim_win_is_valid(process.log_win) then
        vim.api.nvim_set_current_win(process.log_win)
        return
    end

    local width = math.floor(vim.o.columns * 0.8)
    local height = math.floor(vim.o.lines * 0.7)

    process.log_win = vim.api.nvim_open_win(process.log_buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = math.floor((vim.o.lines - height) / 2),
        col = math.floor((vim.o.columns - width) / 2),
        style = "minimal",
        border = "rounded",
        title = (" '%s' logs "):format(process.name),
        title_pos = "left",
    })
    process.log_docked = false

    configure_log_window(process.log_win)

    vim.keymap.set("n", "q", function()
        if process.log_win and vim.api.nvim_win_is_valid(process.log_win) then
            vim.api.nvim_win_close(process.log_win, true)
            process.log_win = nil
        end
    end, { buffer = process.log_buf, nowait = true })

    vim.keymap.set("n", "<C-m>", function()
        if process.log_docked then
            expand_log_window(process)
        else
            dock_log_window(process)
        end
    end, { buffer = process.log_buf, nowait = true })
end

vim.api.nvim_create_autocmd("VimResized", {
    group = vim.api.nvim_create_augroup("workflow_processes", { clear = true }),
    callback = render,
})

return M
