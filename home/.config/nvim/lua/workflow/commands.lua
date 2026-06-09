local project = require("workflow.project")
local processes = require("workflow.processes")
local string_util = require("lib.string")

local M = {}

local config_filename = "launch_commands.json"
local default_commands = {
    {
        name = "hello world",
        command = "echo \"hello world\"",
    },
}

local function command_entry(command, name)
    return {
        name = name or command,
        command = command,
    }
end

local function writable_entry(entry)
    if type(entry) == "string" then
        return command_entry(entry)
    end

    return entry
end

local function encode_config(commands)
    local lines = { "[" }

    for index, raw_entry in ipairs(commands) do
        local entry = writable_entry(raw_entry)
        local suffix = index == #commands and "" or ","

        table.insert(lines, "  {")
        table.insert(lines, "    \"name\": " .. vim.json.encode(entry.name or entry.command) .. ",")
        table.insert(lines, "    \"command\": " .. vim.json.encode(entry.command))

        if entry.cwd then
            lines[#lines] = lines[#lines] .. ","
            table.insert(lines, "    \"cwd\": " .. vim.json.encode(entry.cwd))
        end

        table.insert(lines, "  }" .. suffix)
    end

    table.insert(lines, "]")

    return lines
end

local function config_path(root)
    return project.nvim_dir(root) .. "/" .. config_filename
end

local function read_config(root)
    local path = config_path(root)

    if vim.fn.filereadable(path) == 0 then
        return {}
    end

    local ok, lines = pcall(vim.fn.readfile, path)
    if not ok then
        vim.notify("Could not read " .. path, vim.log.levels.ERROR)
        return {}
    end

    local ok_decode, parsed = pcall(vim.json.decode, table.concat(lines, "\n"))
    if not ok_decode or type(parsed) ~= "table" then
        vim.notify("Invalid " .. config_filename, vim.log.levels.ERROR)
        return {}
    end

    return parsed
end

local function write_config(root, commands)
    local dir = project.nvim_dir(root)
    if vim.fn.isdirectory(dir) == 0 then
        vim.fn.mkdir(dir, "p")
    end

    local ok_write = pcall(vim.fn.writefile, encode_config(commands), config_path(root))
    if not ok_write then
        vim.notify("Could not write " .. config_filename, vim.log.levels.ERROR)
        return false
    end

    return true
end

local function normalize_entry(entry, root)
    if type(entry) == "string" then
        return {
            name = entry,
            command = entry,
            cwd = root,
        }
    end

    if type(entry) ~= "table" or type(entry.command) ~= "string" then
        return nil
    end

    local cwd = vim.fn.expand(entry.cwd or root)
    if not vim.startswith(cwd, "/") then
        cwd = root .. "/" .. cwd
    end

    return {
        name = entry.name or entry.command,
        command = entry.command,
        cwd = cwd,
    }
end

local function normalized_commands(root)
    local commands = {}

    for _, entry in ipairs(read_config(root)) do
        local command = normalize_entry(entry, root)
        if command then
            table.insert(commands, command)
        end
    end

    return commands
end

local function select_label(command)
    local columns = vim.o.columns
    local name_width = math.min(30, math.max(12, math.floor(columns * 0.25)))
    local command_width = math.max(20, columns - name_width - 10)
    local name = string_util.truncate(command.name, name_width)
    local cmd = string_util.truncate(command.command, command_width)

    return string.format("%-" .. name_width .. "s  %s", name, cmd)
end

local function start(command)
    if vim.fn.isdirectory(command.cwd) == 0 then
        vim.notify("Launch cwd does not exist: " .. command.cwd, vim.log.levels.ERROR)
        return
    end

    processes.start({
        name = command.name,
        command = command.command,
        cwd = command.cwd,
    })
end

function M.select_and_start()
    local root = project.find_root()
    if not root then
        vim.notify("No project root found", vim.log.levels.WARN)
        return
    end

    local commands = normalized_commands(root)
    if #commands == 0 then
        vim.notify("No launch commands found in " .. config_path(root), vim.log.levels.WARN)
        return
    end

    vim.ui.select(commands, {
        prompt = "Launch command",
        format_item = function(command)
            return select_label(command)
        end,
    }, function(command)
        if command then
            start(command)
        end
    end)
end

function M.edit()
    local root = project.find_root()
    if not root then
        vim.notify("No project root found", vim.log.levels.WARN)
        return
    end

    if vim.fn.filereadable(config_path(root)) == 0 then
        write_config(root, default_commands)
    end

    vim.cmd("edit " .. vim.fn.fnameescape(config_path(root)))
end

function M.add()
    local root = project.find_root()
    if not root then
        vim.notify("No project root found", vim.log.levels.WARN)
        return
    end

    vim.ui.input({ prompt = "Name: " }, function(name)
        if not name or name == "" then
            return
        end

        vim.ui.input({ prompt = "Command: " }, function(command)
            if not command or command == "" then
                return
            end

            local commands = read_config(root)
            table.insert(commands, command_entry(command, name))

            if write_config(root, commands) then
                vim.notify("Added launch command")
            end
        end)
    end)
end

return M
