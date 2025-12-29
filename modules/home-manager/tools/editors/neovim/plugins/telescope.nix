[
	
  {
	plugin = "telescope-nvim";
	dependencies = [ "plenary-nvim" ];

	keybinds = ''
		local builtin = require("telescope.builtin")
		vim.keymap.set("n", "<leader>fd", builtin.find_files, {})
		vim.keymap.set("n", "<leader>gr", builtin.live_grep, {})
	'';
  }

  {
    plugin = "telescope-ui-select-nvim";
    config = ''
      require("telescope").setup({
        extensions = {
          ["ui-select"] = {
            require("telescope.themes").get_dropdown({}),
          },
        },
        pickers = {
          find_files = {
            hidden = true,
          },
        },
      })
      require("telescope").load_extension("ui-select")
    '';
  }
]
