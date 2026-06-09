-- Files
vim.o.backup = false
vim.o.swapfile = false
vim.o.writebackup = false
vim.o.undofile = true
vim.o.autoread = true
vim.o.fileencoding = "utf-8"

-- Editing
vim.o.expandtab = true
vim.o.shiftwidth = 4
vim.o.tabstop = 4
vim.o.smartindent = true
vim.o.foldenable = false
vim.o.foldmethod = "manual"

-- Search and movement
vim.o.hlsearch = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.scrolloff = 8

-- Layout
vim.o.cmdheight = 3
vim.o.number = true
vim.o.relativenumber = true
vim.o.numberwidth = 4
vim.o.signcolumn = "yes"
vim.o.wrap = false

-- Appearance
vim.o.termguicolors = true
vim.cmd.colorscheme("vscode")
vim.o.guicursor = "n-v-c-i:block"
vim.opt.fillchars = {
    eob = " ",
    vert = "│",
    fold = " ",
    diff = " ",
    msgsep = " ",
}
