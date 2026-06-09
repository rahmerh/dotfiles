local M = {}

local function edit_file(path)
    vim.schedule(function()
        vim.cmd("edit " .. vim.fn.fnameescape(path))
    end)
end

local command_overrides = {
    ["live-grep"] = function(close)
        local tempfile = vim.fn.tempname()
        local cwd = vim.fn.getcwd()

        local command = {
            "fzf",
            "--prompt=rg ",
            "--disabled",
            "--delimiter=:",
            "--with-nth=1,2,4..",
            "--color=bg:-1,bg+:-1,gutter:-1,fg:#e8e8e8,fg+:#ffffff",
            "--color=hl:#e1579c,hl+:#e1579c,info:#999999,prompt:#e1579c",
            "--color=pointer:#e1579c,marker:#e1579c,spinner:#e1579c,header:#999999",
            "--bind=change:reload:test -n {q} && rg --hidden --glob '!**/.git/**' --column --line-number --no-heading --color=never --smart-case -- {q} "
                .. vim.fn.shellescape(cwd)
                .. " || true",
            "--bind=enter:execute-silent(printf '%s\n' {} > " .. vim.fn.shellescape(tempfile) .. ")+abort",
        }

        local on_exit = function()
            if vim.fn.filereadable(tempfile) == 1 then
                local files = vim.fn.readfile(tempfile)
                local result = files[1]
                local file, line, column = nil, nil, nil

                if result then
                    file, line, column = result:match("^(.-):(%d+):(%d+):")
                end

                if file and line and column then
                    vim.schedule(function()
                        vim.cmd("edit " .. vim.fn.fnameescape(file))
                        vim.api.nvim_win_set_cursor(0, { tonumber(line), tonumber(column) - 1 })
                    end)
                end
            end

            close()
        end

        return command, on_exit
    end,

    fzf = function(close)
        local tempfile = vim.fn.tempname()
        local cwd = vim.fn.getcwd()

        local command = {
            "fzf",
            "--prompt= ",
            "--walker=file,hidden",
            "--walker-root=" .. cwd,
            "--walker-skip=.git,node_modules",
            "--color=bg:-1,bg+:-1,gutter:-1,fg:#e8e8e8,fg+:#ffffff",
            "--color=hl:#e1579c,hl+:#e1579c,info:#999999,prompt:#e1579c",
            "--color=pointer:#e1579c,marker:#e1579c,spinner:#e1579c,header:#999999",
            "--bind=enter:execute-silent(printf '%s\n' {} > " .. vim.fn.shellescape(tempfile) .. ")+abort",
        }

        local on_exit = function()
            if vim.fn.filereadable(tempfile) == 1 then
                local files = vim.fn.readfile(tempfile)
                if #files > 0 and files[1] ~= "" then
                    edit_file(files[1])
                end
            end

            close()
        end

        return command, on_exit
    end,

    yazi = function(close)
        local tempfile = vim.fn.tempname()
        local buf_path = vim.fn.expand("%:p:h")

        if buf_path == "" then
            buf_path = vim.uv.cwd()
        end

        local on_exit = function()
            if vim.fn.filereadable(tempfile) == 1 then
                local files = vim.fn.readfile(tempfile)
                if #files > 0 then
                    edit_file(files[1])
                end
            end

            close()
        end

        return { "yazi", "--chooser-file", tempfile, buf_path }, on_exit
    end,
}

function M.resolve(command, close)
    local override = command_overrides[command]
    if override then
        return override(close)
    end

    return command, close
end

return M
