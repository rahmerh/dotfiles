local options = { noremap = true, silent = true }

vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- General
vim.keymap.set("n", "<Space>", "<Nop>", options)

-- Better split navigation
vim.keymap.set("n", "<C-l>", "<C-w>l", options)
vim.keymap.set("n", "<C-h>", "<C-w>h", options)
vim.keymap.set("n", "<C-j>", "<C-w>j", options)
vim.keymap.set("n", "<C-k>", "<C-w>k", options)

-- Editing
vim.keymap.set("n", "L", "<CMD>bnext<CR>", options)
vim.keymap.set("n", "H", "<CMD>bprev<CR>", options)

local function close_buffer()
    if #vim.fn.getbufinfo({ buflisted = 1 }) > 1 then
        local current = vim.api.nvim_get_current_buf()
        vim.cmd("bnext")
        vim.cmd("bdelete " .. current)
    else
        vim.cmd("close")
    end
end

vim.keymap.set("n", "Q", close_buffer, options)

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", options)
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", options)
vim.keymap.set("i", "<C-j>", "<esc><cmd>m .+1<cr>==gi", options)
vim.keymap.set("i", "<C-k>", "<esc><cmd>m .-2<cr>==gi", options)

vim.keymap.set("v", ">", ">gv", options)
vim.keymap.set("v", "<", "<gv", options)

-- Clipboard
vim.keymap.set("x", "<C-p>", [["_dP]])

vim.keymap.set("v", "<leader>y", [["+y]], options)
vim.keymap.set("n", "<leader>y", [["+yy]], options)

vim.keymap.set("n", "<leader>p", [["+p]], options)

-- Terminal
local floatterm = require("terminal")
local build = require("workflow.build")
local commands = require("workflow.commands")
local processes = require("workflow.processes")

vim.keymap.set("n", "<leader>t", function()
    floatterm.activate()
end, options)

vim.keymap.set("n", "<C-t><C-l>", function()
    floatterm.list()
end, options)

vim.keymap.set("n", "<leader>T", function()
    floatterm.new()
end, options)

vim.keymap.set("t", "<C-h>", function()
    floatterm.hide_active_terminal()
end, options)

vim.keymap.set("t", "<C-t><C-n>", function()
    floatterm.cycle(1)
end, options)

vim.keymap.set("t", "<C-t><C-p>", function()
    floatterm.cycle(-1)
end, options)

-- Terminal commands
vim.keymap.set("n", "<leader>f", function()
    floatterm.activate("fzf")
end, options)

vim.keymap.set("n", "<leader>g", function()
    floatterm.activate("live-grep")
end, options)

vim.keymap.set("n", "<C-e>", function()
    floatterm.activate("yazi")
end, options)

vim.keymap.set("n", "<C-g>", function()
    floatterm.activate("lazygit")
end, options)

-- Build
vim.keymap.set("n", "<leader>b", function()
    build.project()
end, options)

vim.keymap.set("n", "<leader>B", function()
    build.workspace()
end, options)

-- Test runner
local test_env = {
    RUST_BACKTRACE = "1",
}

vim.keymap.set("n", "<leader>dn", function()
    require("neotest").run.run({ env = test_env })
end, options)

vim.keymap.set("n", "<leader>df", function()
    require("neotest").run.run({ vim.fn.expand("%"), env = test_env })
end, options)

vim.keymap.set("n", "<leader>dd", function()
    require("neotest").run.run({ strategy = "dap", env = test_env })
end, options)

vim.keymap.set("n", "<leader>do", function()
    require("neotest").output.open({ enter = true })
end, options)

vim.keymap.set("n", "<leader>de", function()
    require("neotest").summary.toggle()
end, options)

-- Debugging
vim.keymap.set("n", "<F5>", "<cmd>DapContinue<cr>", options)
vim.keymap.set("n", "<F10>", "<cmd>DapStepOver<cr>", options)
vim.keymap.set("n", "<F11>", "<cmd>DapStepInto<cr>", options)
vim.keymap.set("n", "<S-F11>", "<cmd>DapStepOut<cr>", options)
vim.keymap.set("n", "<S-F5>", "<cmd>DapTerminate<cr>", options)
vim.keymap.set("n", "<C-b>", function()
    require("debug.breakpoints").toggle()
end, options)
vim.keymap.set("n", "<leader>dl", "<cmd>DapToggleRepl<cr>", options)

-- Workflow
vim.keymap.set("n", "<leader>l", function()
    commands.select_and_start()
end, options)

vim.keymap.set("n", "<leader>me", function()
    commands.edit()
end, options)

vim.keymap.set("n", "<leader>ma", function()
    commands.add()
end, options)

vim.keymap.set("n", "<leader>mc", function()
    processes.clear_exited()
end, options)

for id = 1, 9 do
    vim.keymap.set("n", "<leader>ml" .. id, function()
        processes.open_logs(id)
    end, options)

    vim.keymap.set("n", "<leader>mk" .. id, function()
        processes.kill(id)
    end, options)

    vim.keymap.set("n", "<leader>mv" .. id, function()
        processes.prompt_move(id)
    end, options)
end

-- LSP
vim.keymap.set("n", "<C-.>", "<cmd>lua vim.lsp.buf.code_action()<CR>", options)
vim.keymap.set("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<cr>", options)
vim.keymap.set("n", "gr", "<cmd>lua vim.lsp.buf.references()<cr>", options)
vim.keymap.set("n", "gd", "<cmd>lua vim.lsp.buf.definition()<cr>", options)
vim.keymap.set("n", "<leader>rn", "<cmd>lua vim.lsp.buf.rename()<cr>", options)

vim.keymap.set("n", "<leader>rr", "<cmd>Dotnet lsp restart<cr>", options)

vim.keymap.set("n", "<leader>cc", function()
    require("neogen").generate()
end, vim.tbl_extend("force", options, {
    desc = "Generate documentation comment",
}))
