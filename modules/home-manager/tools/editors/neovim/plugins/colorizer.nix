[
	{
		profile = "full";

		plugin = "nvim-colorizer-lua";
		config = ''
			local colorizer = require("colorizer")
			colorizer.setup({
				filetypes = { "*" },
			})

			-- Autocmd to attach after file loads
			vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
				callback = function()
					require("colorizer").attach_to_buffer(0)
				end,
			})
		'';

		keybinds = ''
			-- Configure colorizer
			function toggle_colorizer(c)
			  if c.is_buffer_attached(0) then
			    c.detach_from_buffer(0)
			  else
			    c.attach_to_buffer(0)
			  end
			end

			local colorizer = require("colorizer")
			vim.keymap.set("n", "<leader>cl", function()
			  toggle_colorizer(colorizer)
			end, {})
		'';
	}
]
