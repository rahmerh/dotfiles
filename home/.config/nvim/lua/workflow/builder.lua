local M = {}

local process_panel = require("ui.process-panel")

local project_types = {
    rust = {
        markers = { "Cargo.toml" },
        build = "cargo build"
    },
    dart = {
        markers = { "pubspec.yaml" },
        build = function(_)
            local ok, args = pcall(vim.fn.input, {
                prompt = "flutter build args (empty for none): ",
                default = "",
            })

            if not ok then
                return nil
            end

            local cmd = "flutter build"

            if args and args:match("%S") then
                cmd = cmd .. " " .. args
            end

            return cmd
        end
    }
}

local active_build_win = nil

local function get_build_cmd_for_current_project()
    local cwd = vim.fn.getcwd()

    for _, meta in pairs(project_types) do
        local has_marker = false

        for _, marker in ipairs(meta.markers) do
            if #vim.fn.glob(cwd .. "/" .. marker, false, true) > 0 then
                has_marker = true
                break
            end
        end

        if not has_marker then
            goto continue
        end

        if type(meta.build) == "function" then
            return meta.build(cwd)
        else
            return meta.build
        end

        ::continue::
    end
end

M.build = function()
    local build_cmd = get_build_cmd_for_current_project()

    if not build_cmd then
        vim.notify("No build command found", vim.log.levels.WARN)
        return
    end

    process_panel.run_passive(build_cmd)
end

M.close_build_log = function()
    if active_build_win and vim.api.nvim_win_is_valid(active_build_win) then
        vim.api.nvim_win_close(active_build_win, true)
        active_build_win = nil
    end
end

return M
