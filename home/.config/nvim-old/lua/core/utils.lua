local M = {}

function M.safe_require(module)
    local ok, lib = pcall(require, module)
    if not ok then
        vim.notify("Missing module: " .. module, vim.log.levels.WARN)
        return nil
    end
    return lib
end

return M
