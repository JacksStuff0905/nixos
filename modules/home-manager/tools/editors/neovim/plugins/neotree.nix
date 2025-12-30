[
	{
		plugin = "neo-tree-nvim";
		dependencies = [
			"plenary-nvim"
			"nvim-web-devicons" # not strictly required, but recommended
			"nui-nvim"
			# Optional image support for file preview: See `# Preview Mode` for more information.
			"image-nvim"
			# OR use snacks.nvim's image module:
			# "folke/snacks.nvim",
		];
		opts = ''
			filesystem = {
				filtered_items = {
					visible = true, -- This is what you want: If you set this to `true`, all "hide" just mean "dimmed out"
					hide_dotfiles = false,
					hide_gitignored = true,
				},
			},
		'';
	}
]
