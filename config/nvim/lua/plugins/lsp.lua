return {
	{
		"williamboman/mason.nvim",
		lazy = false,
		config = function()
			require("mason").setup()
		end,
	},
	{
		"williamboman/mason-lspconfig.nvim",
		lazy = false,
		dependencies = {
			"williamboman/mason.nvim",
		},
		config = function()
			--[[
      require("mason-lspconfig").setup({
       ensure_installed =
          {
            "lua_ls",
            "pyright",
            "omnisharp",
            "bashls",
          }
      })
      ]]
		end,
	},
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		lazy = false,
		dependencies = {
			"williamboman/mason.nvim",
		},
		config = function()
			require("mason-tool-installer").setup({
				ensure_installed = {
					-- Language servers
					"lua-language-server",
					"pyright",
					"omnisharp",
					"bash-language-server",
					"clangd",
					"docker-compose-language-service",
					"dockerfile-language-server",
          "arduino-language-server",
          "html-lsp",
          "css-lsp",
          "biome",
          "jdtls",

					-- Linters
					"cpplint",
					"hadolint",
					"black",
					"gdtoolkit",
          "htmlhint",
          "stylelint",
          "checkstyle",

					-- Formatters
					"stylua",
					"clang-format",
					"isort",
				},
				auto_update = true,
				run_on_start = true,
			})
		end,
	},
	{
		"neovim/nvim-lspconfig",
		lazy = false,
		opts = {
			servers = {
				gdscript = {},
			},
			setup = {
				gdscript = function(_, opts)
					vim.lsp.config.gdscript.setup({
						name = "godot",

						-- Fill in your Godot Language Server parameters
						cmd = vim.lsp.rpc.connect("127.0.0.1", 6005),

						-- Fill in where should Neovim listen to Godot LSP
						-- In this case, "/tmp/godot.pipe"
						on_init = function(client, init_result)
							vim.fn.serverstart("/tmp/godot.pipe")
						end,
					})
					return true
				end,
			},
		},
		config = function()
			local capabilities = require("cmp_nvim_lsp").default_capabilities()

			vim.lsp.enable('lua_ls')
			vim.lsp.enable('pyright')
			vim.lsp.enable('omnisharp')
			vim.lsp.enable('bashls')
			vim.lsp.enable('clangd')
			vim.lsp.enable('docker_compose_language_service')
			vim.lsp.enable('dockerls')
      vim.lsp.enable('gdscript')
      vim.lsp.enable('arduino_language_server')
      vim.lsp.enable('html')
      vim.lsp.enable('cssls')
      vim.lsp.enable('biome')
      vim.lsp.enable('jdtls')
		end,
	},
}
