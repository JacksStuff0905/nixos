return {
	{
		"rktjmp/lush.nvim",
    { dir = vim.fn.resolve(vim.fn.stdpath("config") .. '/current-theme'), lazy = true}
	},
	{
		"mocte4/godotcolour-vim",
		lazy = false,
		priority = 1000,
	},
	{
		"Mofiqul/dracula.nvim",
		lazy = false,
		priority = 1000,
	},
}
