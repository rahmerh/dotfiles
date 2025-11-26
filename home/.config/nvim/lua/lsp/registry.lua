local servers = {
    lua_ls = "lua-language-server",
    bashls = "bash-language-server",
    fish = "fish-lsp",
    gopls = "gopls",
    rust = "rust-analyzer",
    toml = "tombi"
}

local extra_tools = {
    "bash-debug-adapter",
    "codelldb"
}

return {
    servers = servers,
    tools = extra_tools,
}
