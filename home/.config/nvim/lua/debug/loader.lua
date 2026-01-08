local M = {}

local ft_to_module = {
    sh = "debug.bash",
    bash = "debug.bash",
    zsh = "debug.bash",

    rust = "debug.rust",
    go = "debug.go",

    cs = "debug.dotnet",
    fsharp = "debug.dotnet",
}

local loaded = {}

local function load_for_ft(ft)
    local mod = ft_to_module[ft]
    if not mod then
        return
    end

    if loaded[mod] then
        return
    end

    require(mod)
    loaded[mod] = true
end

function M.continue()
    local dap = require("dap")

    local ft = vim.bo.filetype
    load_for_ft(ft)

    dap.continue()
end

return M
