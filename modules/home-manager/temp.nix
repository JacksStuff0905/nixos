{pkgs, config, lib, inputs, ...}:

{

	programs.firefox = {
		enable = true;
	};

	programs.git = {
		enable = true;
		settings = {
			user.name = "Jacek Sawiński";
			user.email = "jacek.sawinski.0905@gmail.com";
		};
	};


	home.packages = [

		# Neovim
		pkgs.python3
		pkgs.perl
		pkgs.curl
		pkgs.unzip
		pkgs.ruby
		#pkgs.python-pip
		#pkgs.npm
		pkgs.lua
		pkgs.luarocks

		pkgs.pkg-config

		pkgs.ripgrep
		pkgs.fd
	];
}
