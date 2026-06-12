local function pack_clean()
    local unused_plugins = {}

    for _, plugin in ipairs(vim.pack.get()) do
        if not plugin.active then
            table.insert(unused_plugins, plugin.spec.name)
        end
    end

    if #unused_plugins == 0 then
        return
    end

    vim.pack.del(unused_plugins)
end

local group = vim.api.nvim_create_augroup("UserAutocommands", { clear = true })

vim.api.nvim_create_user_command("PackCleanUnused", pack_clean, {
    desc = "Remove inactive vim.pack plugins",
})

vim.api.nvim_create_autocmd("VimEnter", {
    group = group,
    desc = "Clean inactive vim.pack plugins after startup",
    callback = function()
        if #vim.api.nvim_list_uis() == 0 then
            return
        end

        vim.defer_fn(pack_clean, 10000)
    end,
})

vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
    group = group,
    desc = "Reload buffers changed on disk when safe",
    callback = function()
        if vim.fn.mode() ~= "c" then
            vim.cmd.checktime()
        end
    end,
})

vim.api.nvim_create_autocmd("FileChangedShellPost", {
    group = group,
    desc = "Report buffers reloaded from disk",
    callback = function()
        vim.notify("Buffer reloaded from disk", vim.log.levels.INFO)
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    group = group,
    desc = "Disable automatic comment continuation",
    callback = function()
        vim.opt_local.formatoptions:remove({ "c", "o", "r" })
    end,
})

local function supports_format(buffer)
    return #vim.lsp.get_clients({
        bufnr = buffer,
        method = "textDocument/formatting",
    }) > 0
end

vim.api.nvim_create_autocmd("BufWritePre", {
    group = group,
    callback = function(event)
        if vim.bo[event.buf].filetype == "proto" and vim.fn.executable("clang-format") == 1 then
            local view = vim.fn.winsaveview()
            vim.cmd([[%!clang-format --assume-filename=% --style='{BasedOnStyle: Google, IndentWidth: 4}']])
            vim.fn.winrestview(view)
            return
        end

        if supports_format(event.buf) then
            vim.lsp.buf.format({
                bufnr = event.buf,
                timeout_ms = 2000,
            })
        end
    end,
})
