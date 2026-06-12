local M = {}

local git_cache = {}

local function filepath()
    local name = vim.fn.expand("%:~:.")
    if name == "" then
        name = "[No Name]"
    end
    return name
end

local function flags()
    local s = ""
    if vim.bo.modified then
        s = s .. " [+]"
    end
    if vim.bo.readonly or not vim.bo.modifiable then
        s = s .. " [RO]"
    end
    return s
end

local function filetype()
    if vim.bo.filetype ~= "" then
        return vim.bo.filetype
    end
    return "-"
end

local function cache_current_git_branch(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    local fname = vim.api.nvim_buf_get_name(bufnr)
    if fname == "" then
        git_cache[bufnr] = { branch = "", status = "clean" }
        return
    end

    local dir = vim.fn.fnamemodify(fname, ":h")

    local function store(entry)
        if not vim.api.nvim_buf_is_valid(bufnr) then
            return
        end
        git_cache[bufnr] = entry
        vim.cmd.redrawstatus()
    end

    vim.system(
        { "git", "-C", dir, "rev-parse", "--abbrev-ref", "HEAD" },
        { text = true },
        function(branch_result)
            if branch_result.code ~= 0 then
                vim.schedule(function()
                    store({ branch = "", status = "clean" })
                end)
                return
            end

            local branch = vim.trim(branch_result.stdout or "")
            if branch == "" or branch == "HEAD" then
                vim.schedule(function()
                    store({ branch = "", status = "clean" })
                end)
                return
            end

            vim.system(
                { "git", "-C", dir, "status", "--porcelain" },
                { text = true },
                function(status_result)
                    local dirty = status_result.code == 0 and vim.trim(status_result.stdout or "") ~= ""

                    vim.schedule(function()
                        store({
                            branch = " " .. branch,
                            status = dirty and "dirty" or "clean",
                        })
                    end)
                end
            )
        end
    )
end

local function git_branch()
    local bufnr = vim.api.nvim_get_current_buf()
    local entry = git_cache[bufnr]
    if not entry or entry.branch == "" then
        return "", "StatusLineGit"
    end

    local hl = "StatusLineGitClean"
    if entry.status == "dirty" then
        hl = "StatusLineGitDirty"
    end

    return entry.branch, hl
end

local function diagnostics()
    local err = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
    local warn = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })

    local parts = {}
    if err > 0 then
        table.insert(parts, "E:" .. err)
    end
    if warn > 0 then
        table.insert(parts, "W:" .. warn)
    end

    if #parts == 0 then
        return ""
    end

    return table.concat(parts, " ")
end

_G.UserStatusline = _G.UserStatusline or {}

function _G.UserStatusline.render()
    local s = "%#StatusLine# " .. filepath() .. flags() .. " "

    s = s .. "%="

    local diag = diagnostics()
    if diag ~= "" then
        s = s .. "%#StatusLineDiag#" .. " " .. diag .. " "
    end

    local git_text, git_hl = git_branch()
    if git_text ~= "" then
        s = s .. "%#" .. git_hl .. "#" .. " " .. git_text .. " "
    end

    s = s .. "%#StatusLine#" .. " " .. filetype() .. " "
    s = s .. "%#StatusLine# %l:%c "

    return s
end

function M.setup()
    local group = vim.api.nvim_create_augroup("UserStatusline", { clear = true })

    local function apply_highlights()
        vim.api.nvim_set_hl(0, "StatusLine", {
            fg = "#bbbbbb",
            bg = "NONE",
            bold = false,
        })

        vim.api.nvim_set_hl(0, "StatusLineGit", {
            fg = "#bbbbbb",
            bg = "NONE",
            bold = false,
        })

        vim.api.nvim_set_hl(0, "StatusLineGitClean", {
            fg = "#bbbbbb",
            bg = "NONE",
            bold = false,
        })

        vim.api.nvim_set_hl(0, "StatusLineGitDirty", {
            fg = "#ebcb8b",
            bg = "NONE",
            bold = false,
        })

        vim.api.nvim_set_hl(0, "StatusLineDiag", {
            fg = "#ebcb8b",
            bg = "NONE",
            bold = false,
        })
    end

    vim.o.laststatus = 3
    vim.o.statusline = "%!v:lua.UserStatusline.render()"

    apply_highlights()

    vim.api.nvim_create_autocmd("ColorScheme", {
        group = group,
        callback = apply_highlights,
    })

    vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "FocusGained" }, {
        group = group,
        callback = function(args)
            cache_current_git_branch(args.buf)
        end,
    })

    vim.api.nvim_create_autocmd("BufDelete", {
        group = group,
        callback = function(args)
            git_cache[args.buf] = nil
        end,
    })
end

return M
