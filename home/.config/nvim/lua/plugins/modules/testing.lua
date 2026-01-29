return {
    {
        "nvim-neotest/neotest",
        dependencies = {
            "rouge8/neotest-rust",
            "Issafalcon/neotest-dotnet"
        },
        keys = {
            { "<leader>tn", function() require("neotest").run.run() end,                     desc = "Run nearest test" },
            { "<leader>tf", function() require("neotest").run.run(vim.fn.expand("%")) end,   desc = "Run file tests" },
            { "<leader>td", function() require("neotest").run.run({ strategy = "dap" }) end, desc = "Run test with DAP" },
            { "<leader>to", function() require("neotest").output.open({ enter = true }) end, desc = "Open test output" },
            { "<leader>te", function() require("neotest").summary.toggle() end,              desc = "Toggle test summary" },
        },
        config = function()
            require("neotest").setup({
                adapters = {
                    require('rustaceanvim.neotest'),
                    require("neotest-dotnet")
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
            local proj_util = require("util.project")

            cov.setup({
                auto_reload = true,
            })

            cov._lazy_toggle = (function()
                local loaded = false

                local lcov_names = {
                    "lcov.info",
                    "coverage.info",
                }

                return function()
                    if loaded then
                        cov.clear()
                        loaded = false
                        return
                    end

                    local root = proj_util.find_project_root(vim.bo.filetype)
                    local matches = proj_util.find_files_upwards(root, lcov_names)

                    if #matches == 0 then
                        vim.notify("No lcov file found", vim.log.levels.WARN)
                        return
                    end

                    table.sort(matches)
                    local path = matches[#matches]

                    cov.load_lcov(path, true)
                    loaded = true

                    vim.notify(
                        "Loaded coverage: " .. vim.fn.fnamemodify(path, ":~:."),
                        vim.log.levels.INFO
                    )
                end
            end)()

            cov._lazy_generate = (function()
                return function()
                    local ft = vim.bo.filetype
                    local cmd, output

                    vim.notify("Coverage generating...", vim.log.levels.INFO)

                    local proj_root = proj_util.find_project_root()
                    if ft == "rust" then
                        vim.fn.mkdir(proj_root .. "target/llvm-cov", "p")
                        cmd = {
                            "cargo", "llvm-cov", "nextest",
                            "--lcov", "--output-path", "target/llvm-cov/lcov.info"
                        }
                        output = proj_root .. "target/llvm-cov/lcov.info"
                    elseif ft == "cs" then
                        vim.fn.mkdir(proj_root .. "/TestResults/llvm-cov", "p")

                        cmd = {
                            "dotnet", "test",
                            "--filter", "Category!=Integration",
                            '--collect:XPlat Code Coverage',
                            "--",
                            "DataCollectionRunSettings.DataCollectors.DataCollector.Configuration.Format=lcov",
                        }

                        output = "Generated in test projects."
                    else
                        vim.notify("No coverage generator for filetype: " .. ft, vim.log.levels.WARN)
                        return
                    end

                    vim.system(cmd, { text = true, cwd = proj_root }, function(res)
                        vim.schedule(function()
                            if res.code == 0 then
                                vim.notify("Coverage generated: " .. output, vim.log.levels.INFO)
                            else
                                vim.notify("Coverage failed:\n" .. res.stderr .. res.stdout, vim.log.levels.ERROR)
                            end
                        end)
                    end)
                end
            end)()
        end,
    },
}
