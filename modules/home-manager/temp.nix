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
}
