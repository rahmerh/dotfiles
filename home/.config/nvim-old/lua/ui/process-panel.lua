local M = {}

local function open_floating_window(enter)
    local buf = vim.api.nvim_create_buf(false, true)

    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].swapfile = false
    vim.bo[buf].modifiable = true
    vim.bo[buf].filetype = "log"

    local win_width = math.floor(vim.o.columns * 0.2)
    local win_height = math.floor(vim.o.lines * 0.8)

    local win = vim.api.nvim_open_win(buf, enter, {
        relative = "editor",
        anchor = "NE",
        width = win_width,
        height = win_height,
        row = 1,
        col = vim.o.columns,
        style = "minimal",
        border = "none",
        focusable = true,
        zindex = 50,
    })

    vim.wo[win].wrap = true
    vim.wo[win].linebreak = true
    vim.wo[win].breakindent = true
    vim.wo[win].breakindentopt = "shift:2"
    vim.wo[win].showbreak = "↪ "

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

    local map_opts = { buffer = buf, silent = true, nowait = true }

    vim.keymap.set("n", "j", "<C-e>", map_opts)
    vim.keymap.set("n", "k", "<C-y>", map_opts)
    vim.keymap.set("n", "<Down>", "<C-e>", map_opts)
    vim.keymap.set("n", "<Up>", "<C-y>", map_opts)
    vim.keymap.set("n", "<PageDown>", "<C-f>", map_opts)
    vim.keymap.set("n", "<PageUp>", "<C-b>", map_opts)

    vim.keymap.set("n", "gg", "gg", map_opts)
    vim.keymap.set("n", "G", "G", map_opts)

    vim.keymap.set("n", "q", function()
        if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, true)
        end
        if vim.api.nvim_buf_is_valid(buf) then
            vim.api.nvim_buf_delete(buf, { force = true })
        end
    end, map_opts)

    return buf, win
end


M.run_passive = function(cmd, opts)
    opts = opts or {}

    local buf, win = open_floating_window(false)
    vim.b[buf].process_panel = true
    vim.bo[buf].buflisted = false

    local function append(lines)
        if lines and #lines > 0 then
            if #lines == 1 and lines[1] == "" then return end

            for i, line in ipairs(lines) do
                lines[i] = line
                    :gsub("\27%[%d*K", "")
                    :gsub("\27%[%d*G", "")
                    :gsub("\r", "")
            end

            local line_count = vim.api.nvim_buf_line_count(buf)
            vim.api.nvim_buf_set_lines(buf, -1, -1, false, lines)
            vim.api.nvim_win_set_cursor(win, { line_count + #lines, 0 })
        end
    end

    vim.fn.jobstart(cmd, {
        pty = false,
        stdout_buffered = false,
        stderr_buffered = false,
        on_stdout = function(_, data) append(data) end,
        on_stderr = function(_, data) append(data) end,
        on_exit = function(_, code)
            local color = code == 0 and "\x1b[32m" or "\x1b[31m"
            local msg = { "\tProcess exited with code: " .. color .. code .. "\x1b[37m" }

            local line = vim.api.nvim_buf_line_count(buf)

            local win_height = vim.api.nvim_win_get_height(win)
            local buf_line_count = vim.api.nvim_buf_line_count(buf)

            if buf_line_count < win_height then
                local padding = {}
                for _ = 1, win_height - buf_line_count do
                    padding[#padding + 1] = ""
                end
                vim.api.nvim_buf_set_lines(buf, -1, -1, false, padding)
            end

            local timer = vim.loop.new_timer()
            local countdown = 10
            local ns = vim.api.nvim_create_namespace("builder_timer")

            timer:start(0, 1000, vim.schedule_wrap(function()
                if not vim.api.nvim_win_is_valid(win) then
                    timer:stop()
                    return
                end

                if countdown < 0 then
                    timer:stop()
                    vim.api.nvim_win_close(win, true)
                    return
                end

                local msg = countdown .. "s"
                vim.api.nvim_buf_clear_namespace(buf, ns, win_height - 1, win_height)
                vim.api.nvim_buf_set_extmark(buf, ns, win_height - 1, 0, {
                    virt_text = { { msg, "Comment" } },
                    virt_text_pos = "right_align",
                })

                countdown = countdown - 1
            end))

            if opts.on_exit then
                opts.on_exit(code)
            end
        end,
    })
end

M.run_active = function(cmd)
    local origin_win = vim.api.nvim_get_current_win()

    local buf, win = open_floating_window(true)

    vim.b[buf].process_panel = true
    vim.bo[buf].buflisted = false

    vim.wo[win].winblend = 20
    vim.wo[win].winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder"

    local job_id = vim.fn.jobstart(cmd, {
        term = true,
        pty = true,
    })

    local function stop_job()
        if job_id and job_id > 0 then
            vim.fn.jobstop(job_id)
            job_id = nil
        end
    end

    local function close_panel()
        stop_job()

        if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, true)
        end
        if vim.api.nvim_buf_is_valid(buf) then
            vim.b[buf].process_panel = nil
            vim.api.nvim_buf_delete(buf, { force = true })
        end
    end

    local function leave_panel()
        vim.cmd("stopinsert")

        if vim.api.nvim_win_is_valid(origin_win) then
            vim.api.nvim_set_current_win(origin_win)
        end
    end

    vim.keymap.set("t", "<C-e>", leave_panel, { buffer = buf, nowait = true })
    vim.keymap.set("t", "<Esc><Esc>", function()
        vim.cmd("stopinsert")
        close_panel()
    end, { buffer = buf, nowait = true })

    vim.defer_fn(function()
        vim.cmd("startinsert")
    end, 50)
end

local function find_process_panel_win()
    for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
        for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
            local b = vim.api.nvim_win_get_buf(win)
            if vim.api.nvim_buf_is_valid(b) and vim.b[b].process_panel then
                return win, b, tab
            end
        end
    end
end

function M.enter_active_panel()
    local win, buf, tab = find_process_panel_win()
    if not win then
        return
    end

    if vim.api.nvim_get_current_tabpage() ~= tab then
        vim.api.nvim_set_current_tabpage(tab)
    end

    if vim.api.nvim_get_current_win() ~= win then
        vim.api.nvim_set_current_win(win)
    end

    if vim.bo[buf].buftype == "terminal" then
        vim.cmd("startinsert")
    end
end

return M
