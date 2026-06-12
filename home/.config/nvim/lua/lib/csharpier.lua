local M = {}

local state = {
    job = nil,
    port = nil,
    starting = false,
    failed = false,
}

local function server_cmd()
    if vim.fn.executable("csharpier") == 1 then
        return { "csharpier", "server" }
    elseif vim.fn.executable("dotnet") == 1 then
        return { "dotnet", "csharpier", "server" }
    end

    return nil
end

local function post(body, timeout)
    return vim.system({
        "curl",
        "--silent",
        "--max-time",
        tostring(timeout),
        "-X",
        "POST",
        "-H",
        "Content-Type: application/json",
        "--data-binary",
        "@-",
        "http://127.0.0.1:" .. state.port .. "/format",
    }, { stdin = body })
end

local function warm()
    local body = vim.json.encode({
        fileName = "/" .. tostring(vim.uv.hrtime()) .. "/Warmup.cs",
        fileContents = "public class ClassName { }",
    })

    post(body, 5)
end

function M.start()
    if state.job or state.starting or state.failed then
        return
    end

    if vim.fn.executable("curl") ~= 1 then
        state.failed = true
        return
    end

    local cmd = server_cmd()
    if not cmd then
        state.failed = true
        return
    end

    state.starting = true

    local stdout = ""

    state.job = vim.system(cmd, {
        env = { DOTNET_NOLOGO = "1" },
        stdout = function(_, data)
            if not data or state.port then
                return
            end

            stdout = stdout .. data
            local port = stdout:match("Started on (%d+)")
            if port then
                state.port = tonumber(port)
                vim.schedule(warm)
            end
        end,
    }, function(obj)
        state.job = nil
        state.port = nil
        state.starting = false
        if obj.code ~= 0 then
            state.failed = true
        end
    end)
end

function M.stop()
    if state.job then
        state.job:kill("sigterm")
    end
end

function M.format(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()

    M.start()
    if state.failed then
        return
    end

    if not state.port then
        vim.wait(2000, function()
            return state.port ~= nil or state.failed
        end, 20)
    end

    if not state.port then
        return
    end

    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local body = vim.json.encode({
        fileName = vim.api.nvim_buf_get_name(bufnr),
        fileContents = table.concat(lines, "\n"),
    })

    local result = post(body, 5):wait()
    if result.code ~= 0 or not result.stdout or result.stdout == "" then
        return
    end

    local ok, decoded = pcall(vim.json.decode, result.stdout)
    if not ok or type(decoded) ~= "table" then
        return
    end

    if decoded.status ~= "Formatted" or not decoded.formattedFile then
        return
    end

    local formatted = vim.split(decoded.formattedFile, "\n", { plain = true })
    if formatted[#formatted] == "" then
        table.remove(formatted)
    end

    if not vim.deep_equal(lines, formatted) then
        local view = vim.fn.winsaveview()
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, formatted)
        vim.fn.winrestview(view)
    end
end

return M
