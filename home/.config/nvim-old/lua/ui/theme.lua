local gray = "#313233";
local pink = "#E85A98";

-- Telescope
vim.api.nvim_set_hl(0, "TelescopeMatching", { fg = pink, bold = true, italic = true })
vim.api.nvim_set_hl(0, "TelescopeSelection", { bg = pink })

vim.api.nvim_set_hl(0, "TelescopePromptTitle", { fg = gray, bold = true })
vim.api.nvim_set_hl(0, "TelescopePromptPrefix", { fg = gray })
vim.api.nvim_set_hl(0, "TelescopePromptCounter", { fg = gray })
vim.api.nvim_set_hl(0, "TelescopePromptNormal", { bg = gray })
vim.api.nvim_set_hl(0, "TelescopePromptBorder", { fg = gray, bg = gray })

vim.api.nvim_set_hl(0, "TelescopeResultsTitle", { fg = gray, bg = gray, bold = true })
vim.api.nvim_set_hl(0, "TelescopeResultsNormal", { bg = gray })
vim.api.nvim_set_hl(0, "TelescopeResultsBorder", { fg = gray, bg = gray })

vim.api.nvim_set_hl(0, "TelescopePreviewTitle", { fg = gray, bold = true })
vim.api.nvim_set_hl(0, "TelescopePreviewNormal", { bg = gray })
vim.api.nvim_set_hl(0, "TelescopePreviewBorder", { fg = gray, bg = gray })

-- Window settings
vim.api.nvim_set_hl(0, "NormalFloat", { bg = gray })
