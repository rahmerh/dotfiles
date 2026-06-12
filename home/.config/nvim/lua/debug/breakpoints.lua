local M = {}

local save_dir = vim.fn.stdpath("data") .. "/nvim_checkpoints"

local function storage_path()
    local key = vim.fn.getcwd():gsub("/", "_")
    return save_dir .. "/" .. key .. ".json"
end

local function read_store()
    local fd = io.open(storage_path(), "r")
    if not fd then
        return {}
    end

    local raw = fd:read("*a")
    fd:close()

    local ok, decoded = pcall(vim.json.decode, raw)
    if not ok or type(decoded) ~= "table" then
        return {}
    end

    return decoded
end

local function write_store(store)
    vim.fn.mkdir(save_dir, "p")

    local fd = io.open(storage_path(), "w")
    if not fd then
        vim.notify("Failed to save breakpoints", vim.log.levels.WARN)
        return
    end

    fd:write(vim.json.encode(store))
    fd:close()
end

local function save_current()
    local breakpoints = require("dap.breakpoints")
    local bufnr = vim.api.nvim_get_current_buf()
    local name = vim.api.nvim_buf_get_name(bufnr)
    if name == "" then
        return
    end

    local store = read_store()
    local bps = breakpoints.get()[bufnr]

    if bps and #bps > 0 then
        store[name] = bps
    else
        store[name] = nil
    end

    write_store(store)
end

function M.toggle()
    require("dap").toggle_breakpoint()
    save_current()
end

function M.load()
    local breakpoints = require("dap.breakpoints")
    local store = read_store()
    local current = breakpoints.get()

    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        local name = vim.api.nvim_buf_get_name(bufnr)
        local saved = store[name]

        if current[bufnr] == nil and saved and #saved > 0 then
            for _, bp in ipairs(saved) do
                breakpoints.set({
                    condition = bp.condition,
                    log_message = bp.logMessage,
                    hit_condition = bp.hitCondition,
                }, bufnr, bp.line)
            end
        end
    end
end

function M.setup()
    local group = vim.api.nvim_create_augroup("UserPersistentBreakpoints", { clear = true })

    vim.api.nvim_create_autocmd("BufReadPost", {
        group = group,
        callback = M.load,
    })
end

return M
