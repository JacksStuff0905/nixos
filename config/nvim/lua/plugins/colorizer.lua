return {
	{
		"norcalli/nvim-colorizer.lua",
		config = function()
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
		end,
	},
}
