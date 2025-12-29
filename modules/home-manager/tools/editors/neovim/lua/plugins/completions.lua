return {
	{
		"hrsh7th/cmp-nvim-lsp",
	},
	{
		"L3MON4D3/LuaSnip",
		dependencies = {
			"saadparwaiz1/cmp_luasnip",
			"rafamadriz/friendly-snippets",
		},
	},
	--[[ {
		"tzachar/cmp-ai",
		dependencies = { "nvim-lua/plenary.nvim" },
		lazy = false,
		config = function()
			local cmp_ai = require("cmp_ai.config")

			cmp_ai:setup({
				max_lines = 100,
				provider = "Ollama",
				provider_options = {
					model = "codegemma:2b-code",
					prompt = function(lines_before, lines_after)
						return lines_before
					end,
					suffix = function(lines_after)
						return lines_after
					end,
				},
				notify = true,
				notify_callback = function(msg)
					vim.notify(msg)
				end,
				run_on_every_keystroke = true,
			})
		end,
	}, ]]--
	{
		"hrsh7th/nvim-cmp",
		config = function()
			local cmp = require("cmp")

			-- Load vscode-like snippets from friendly-snippets to Luasnip
			require("luasnip.loaders.from_vscode").lazy_load()

			cmp.setup({
				snippet = {
					expand = function(args)
						require("luasnip").lsp_expand(args.body)
					end,
				},
				window = {
					completion = cmp.config.window.bordered({
						border = "rounded",
						col_offset = -1,
						scrollbar = false,
						scrolloff = 3,
						winhighlight = "Normal:Pmenu,FloatBorder:Pmenu,CursorLine:PmenuSel,Search:None",
					}),
					documentation = cmp.config.window.bordered({
						border = "rounded",
						scrollbar = false,

						winhighlight = "Normal:Pmenu,FloatBorder:Pmenu,CursorLine:PmenuSel,Search:None",
					}),
				},
				mapping = cmp.mapping.preset.insert({
					["<C-b>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					["<C-Space>"] = cmp.mapping.complete(),
					["<C-e>"] = cmp.mapping.abort(),
					["<CR>"] = cmp.mapping.confirm({ select = true }),
				}),
				sources = cmp.config.sources({
					{ name = "nvim_lsp" },
					{ name = "luasnip" },
					{ name = "cmp_ai" },
				}, {
					{ name = "buffer" },
				}),
			})
		end,
	},
}
