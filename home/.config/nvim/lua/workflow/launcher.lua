local M = {}

local process_panel = require("ui.process-panel")

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values

local json = vim.fn.json_decode
local encode = vim.fn.json_encode
local decode = vim.fn.json_decode

local project_root_markers = {
    rust = {
        markers = { "Cargo.toml" },
    },
    dart = {
        markers = { "pubspec.yaml" },
    },
    html = {
        markers = { "index.html" },
    }
}

local function find_project_root()
    local path = vim.fn.expand("%:p:h")

    while path and path ~= "/" do
        for _, meta in pairs(project_root_markers) do
            for _, marker in ipairs(meta.markers) do
                local glob = vim.fn.glob(path .. "/" .. marker)
                if glob ~= "" then
                    return path
                end
            end
        end
        path = vim.fn.fnamemodify(path, ":h")
    end

    return nil
end

local function read_launch_config(project_root)
    local config_path = project_root .. "/.nvim/launch_commands.json"
    if vim.fn.filereadable(config_path) == 0 then
        return {}
    end

    local ok, content = pcall(vim.fn.readfile, config_path)
    if not ok then
        vim.notify("Failed to read launch_commands.json", vim.log.levels.ERROR)
        return {}
    end

    local ok2, parsed = pcall(decode, table.concat(content, "\n"))
    if not ok2 or type(parsed) ~= "table" then
        vim.notify("Invalid launch_commands.json format", vim.log.levels.ERROR)
        return {}
    end

    return parsed
end

local function get_commands_file()
    local root = find_project_root()
    if not root then return nil end

    local dir = root .. "/.nvim"
    if vim.fn.isdirectory(dir) == 0 then
        vim.fn.mkdir(dir)
    end

    return dir .. "/launch_commands.json"
end

local function read_commands()
    local file = get_commands_file()

    if not file or vim.fn.filereadable(file) == 0 then
        vim.notify("Failed to read launch_commands.json", vim.log.levels.ERROR)
        return
    end

    local content = vim.fn.readfile(file)
    return json(table.concat(content, "\n")) or {}
end

local function write_commands(cmds)
    local file = get_commands_file()

    if not file then
        vim.notify("Failed to read launch_commands.json", vim.log.levels.ERROR)
        return
    end

    if file then
        vim.fn.writefile({ encode(cmds) }, file)
    end
end

M.launch = function()
    local project_root = find_project_root()

    if not project_root then
        vim.notify("No project root found", vim.log.levels.WARN)
        return
    end

    local launch_commands = read_launch_config(project_root)

    pickers.new({}, {
        layout_config = {
            width = 0.3,
            height = 0.5,
            prompt_position = "top",
        },
        layout_strategy = "horizontal",
        prompt_title = "Launch command",
        finder = finders.new_table({
            results = launch_commands,
        }),
        sorter = conf.generic_sorter({}),
        attach_mappings = function(_, map)
            map("i", "<CR>", function(prompt_bufnr)
                local action_state = require("telescope.actions.state")
                local actions = require("telescope.actions")
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)

                if selection then
                    process_panel.run_active(selection[1])
                end
            end)
            return true
        end,
    }):find()
end

M.manage_commands = function()
    local cmds = read_commands()
    local buf = vim.api.nvim_create_buf(false, true)
    local ns = vim.api.nvim_create_namespace("launch_cmd_ui")

    local width = 80
    local height = math.max(10, #cmds + 3)
    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = math.floor((vim.o.lines - height) / 2),
        col = math.floor((vim.o.columns - width) / 2),
        style = "minimal",
        border = "none",
    })

    local function redraw()
        vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

        local lines = vim.deepcopy(cmds)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

        local win_height = vim.api.nvim_win_get_height(win)
        local virt_line = win_height - 1

        local buf_line_count = vim.api.nvim_buf_line_count(buf)
        if buf_line_count < win_height then
            local padding = {}
            for _ = 1, win_height - buf_line_count do
                table.insert(padding, "")
            end
            vim.api.nvim_buf_set_lines(buf, -1, -1, false, padding)
        end

        vim.api.nvim_buf_set_extmark(buf, ns, virt_line, 0, {
            virt_text = { { "a: new  x: rm  q: exit", "Comment" } },
            virt_text_pos = "right_align",
        })
    end

    redraw()
    vim.bo[buf].modifiable = false

    vim.keymap.set("n", "q", function()
        vim.api.nvim_win_close(win, true)
    end, { buffer = buf })

    vim.keymap.set("n", "x", function()
        vim.bo[buf].modifiable = true
        local line = vim.fn.line(".")
        if line <= #cmds then
            table.remove(cmds, line)
            redraw()
            write_commands(cmds)
        end
        vim.bo[buf].modifiable = false
    end, { buffer = buf })

    vim.keymap.set("n", "a", function()
        table.insert(cmds, "")
        vim.bo[buf].modifiable = true
        redraw()

        local line = #cmds
        vim.api.nvim_win_set_cursor(win, { line, 0 })

        vim.api.nvim_set_hl(0, "DimmedComment", {
            fg = "#5c6370",
            italic = true,
        })
        vim.api.nvim_buf_set_extmark(buf, ns, line - 1, 0, {
            hl_mode = "combine",
            virt_text = { { "'<esc> to save'", "DimmedComment" } },
            virt_text_pos = "eol",
        })

        vim.api.nvim_create_autocmd("InsertLeave", {
            buffer = buf,
            once = true,
            callback = function()
                vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

                local new_line = vim.api.nvim_buf_get_lines(buf, line - 1, line, false)[1]
                if new_line and new_line ~= "" then
                    cmds[line] = new_line
                else
                    table.remove(cmds, line)
                end

                redraw()
                write_commands(cmds)
                vim.bo[buf].modifiable = false
            end,
        })

        vim.cmd("startinsert")
    end, { buffer = buf })
end

return M
