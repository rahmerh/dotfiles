return {
    {
        "nvim-neotest/neotest",
        dependencies = { "rouge8/neotest-rust" },
        keys = {
            { "<leader>tn", function() require("neotest").run.run() end,                     desc = "Run nearest test" },
            { "<leader>tf", function() require("neotest").run.run(vim.fn.expand("%")) end,   desc = "Run file tests" },
            { "<leader>td", function() require("neotest").run.run({ strategy = "dap" }) end, desc = "Run test with DAP" },
            { "<leader>to", function() require("neotest").output.open({ enter = true }) end, desc = "Open test output" },
            { "<leader>ts", function() require("neotest").summary.toggle() end,              desc = "Toggle test summary" },
        },
        config = function()
            require("neotest").setup({
                adapters = {
                    require('rustaceanvim.neotest')
                }
            })
        end,
    },
    {
        "andythigpen/nvim-coverage",
        dependencies = { "nvim-lua/plenary.nvim" },
        keys = {
            {
                "<leader>cv",
                function()
                    require("coverage")._lazy_toggle()
                end,
                desc = "Toggle code coverage"
            },
            {
                "<leader>cs",
                function()
                    require("coverage").summary()
                end,
                desc = "Show coverage summary"
            },
            {
                "<leader>cc",
                function()
                    require("coverage")._lazy_generate()
                end,
                desc = "Generate LCOV coverage"
            },
        },
        config = function()
            local cov = require("coverage")

            cov.setup({
                auto_reload = true,
            })

            cov._lazy_toggle = (function()
                local loaded = false

                local function find_lcov_file()
                    local candidates = {
                        "target/llvm-cov/lcov.info",
                        "coverage/lcov.info",
                        "coverage.info",
                        "lcov.info",
                    }
                    for _, path in ipairs(candidates) do
                        if vim.fn.filereadable(path) == 1 then
                            return path
                        end
                    end
                    return nil
                end

                return function()
                    if loaded then
                        cov.clear()
                        loaded = false
                    else
                        local path = find_lcov_file()
                        if path then
                            cov.load_lcov(path, true)
                            loaded = true
                        else
                            vim.notify("No lcov file found", vim.log.levels.WARN)
                        end
                    end
                end
            end)()

            cov._lazy_generate = (function()
                return function()
                    local ft = vim.bo.filetype
                    local cmd, output

                    vim.notify("Coverage generating...", vim.log.levels.INFO)

                    if ft == "rust" then
                        vim.fn.mkdir("target/llvm-cov", "p")
                        cmd = {
                            "cargo", "llvm-cov", "nextest",
                            "--lcov", "--output-path", "target/llvm-cov/lcov.info"
                        }
                        output = "target/llvm-cov/lcov.info"
                    else
                        vim.notify("No coverage generator for filetype: " .. ft, vim.log.levels.WARN)
                        return
                    end

                    vim.system(cmd, { text = true }, function(res)
                        vim.schedule(function()
                            if res.code == 0 then
                                vim.notify("Coverage generated: " .. output, vim.log.levels.INFO)
                            else
                                vim.notify("Coverage failed:\n" .. res.stderr, vim.log.levels.ERROR)
                            end
                        end)
                    end)
                end
            end)()
        end,
    },
}
