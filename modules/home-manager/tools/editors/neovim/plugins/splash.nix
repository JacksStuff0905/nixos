[
	{
		plugin = "alpha-nvim";
		dependencies = [ "mini-icons" ];
		config = ''
			require("alpha").setup(require("alpha.themes.startify").config)
		'';
	}
]
