local general = vim.api.nvim_create_augroup("_general_settings", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
    group = general,
    pattern = { "qf", "help", "man", "lspinfo" },
    callback = function()
        vim.keymap.set("n", "q", ":close<CR>", { buffer = true, silent = true })
    end,
})

vim.api.nvim_create_autocmd("BufWinEnter", {
    group = general,
    pattern = "*",
    callback = function()
        vim.opt_local.formatoptions:remove({ "c", "r", "o" })
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    group = general,
    pattern = "qf",
    command = "set nobuflisted",
})

local git = vim.api.nvim_create_augroup("_git", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
    group = git,
    pattern = "gitcommit",
    callback = function()
        vim.opt_local.wrap = true
        vim.opt_local.spell = true
    end,
})

local markdown = vim.api.nvim_create_augroup("_markdown", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
    group = markdown,
    pattern = "markdown",
    callback = function()
        vim.opt_local.wrap = true
        vim.opt_local.spell = true
    end,
})

local resize = vim.api.nvim_create_augroup("_auto_resize", { clear = true })

vim.api.nvim_create_autocmd("VimResized", {
    group = resize,
    command = "tabdo wincmd =",
})

local fmt = vim.api.nvim_create_augroup("FormatAutogroup", { clear = true })

vim.api.nvim_create_autocmd("BufWritePre", {
    group = fmt,
    callback = function()
        vim.lsp.buf.format({ async = false })
    end,
})

local transparent = vim.api.nvim_create_augroup("TransparentBackground", { clear = true })

vim.api.nvim_create_autocmd("VimEnter", {
    group = transparent,
    callback = function()
        vim.cmd("hi Normal guibg=NONE ctermbg=NONE")
    end,
})

vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
    callback = function()
        vim.cmd("checktime")
    end,
})

vim.opt.laststatus = 3
vim.opt.mouse = "n"
