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
    local git_root = vim.fn.systemlist(
        "git -C " .. vim.fn.shellescape(dir) .. " rev-parse --show-toplevel 2>/dev/null"
    )[1]

    if vim.v.shell_error ~= 0 or not git_root or git_root == "" then
        git_cache[bufnr] = { branch = "", status = "clean" }
        return
    end

    local branch = vim.fn.systemlist(
        "git -C " .. vim.fn.shellescape(git_root) .. " rev-parse --abbrev-ref HEAD 2>/dev/null"
    )[1]

    if vim.v.shell_error ~= 0 or not branch or branch == "" or branch == "HEAD" then
        git_cache[bufnr] = { branch = "", status = "clean" }
        return
    end

    -- Determine status: clean vs dirty
    local status_lines = vim.fn.systemlist(
        "git -C " .. vim.fn.shellescape(git_root) .. " status --porcelain=v2 --branch 2>/dev/null"
    )

    local dirty = false
    if vim.v.shell_error == 0 and status_lines and #status_lines > 0 then
        for _, line in ipairs(status_lines) do
            -- Any non-comment line in porcelain output = something changed
            if not line:match("^#") then
                dirty = true
                break
            end
        end
    end

    git_cache[bufnr] = {
        branch = " " .. branch,
        status = dirty and "dirty" or "clean",
    }
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

function _G.MyStatusline()
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
    local function apply_highlights()
        vim.api.nvim_set_hl(0, "StatusLine", {
            fg = "#bbbbbb",
            bg = "NONE",
            bold = false,
        })

        -- fallback
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
    vim.o.statusline = "%!v:lua.MyStatusline()"

    apply_highlights()

    vim.api.nvim_create_autocmd("ColorScheme", {
        callback = apply_highlights,
    })

    vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "FocusGained" }, {
        callback = function(args)
            cache_current_git_branch(args.buf)
        end,
    })
end

return M
