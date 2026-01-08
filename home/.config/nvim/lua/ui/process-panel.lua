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
    local baleia = require("baleia").setup({})
    baleia.automatically(buf)

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
            baleia.buf_set_lines(buf, line, line, true, msg)

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
    local buf, win = open_floating_window(true)

    vim.wo[win].winblend = 20
    vim.wo[win].winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder"

    vim.fn.jobstart(cmd, {
        term = true,
        pty = true,
    })

    vim.keymap.set("n", "q",
        function(_, _)
            if vim.api.nvim_win_is_valid(win) then
                vim.api.nvim_win_close(win, true)
            end
            if vim.api.nvim_buf_is_valid(buf) then
                vim.api.nvim_buf_delete(buf, { force = true })
            end
        end,
        { buffer = buf, nowait = true })

    vim.defer_fn(function()
        vim.cmd("startinsert")
    end, 50)
end

return M
