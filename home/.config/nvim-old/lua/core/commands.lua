vim.api.nvim_create_user_command("W", 'execute "SudaWrite"', {})
vim.api.nvim_create_user_command("E", 'execute "SudaRead"', {})
vim.api.nvim_create_user_command("Wnf", function()
    vim.b.no_autoformat = true
    vim.cmd("write")
    vim.b.no_autoformat = false
end, {
    desc = "Write buffer without formatting",
})
