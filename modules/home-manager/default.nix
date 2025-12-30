{ config, lib, pkgs, ... }:

{
	imports = [
		./apps
		./fonts
		./themes
		./tools
		./sh
		./srv
	];

  options.default = {
	username = lib.mkOption {
		type = lib.types.str;
	};
	homeDirectory = lib.mkOption {
		type = lib.types.str;
	};
  };

  config = {
	# Shell config
	sh.zsh.enable = true;
	sh.aliases.enable = true;
	sh.env-vars.enable = true;

	# Desktop apps
	apps.godot.enable = true;
	apps.spotify.enable = true;
	apps.kitty.enable = true;
	apps.keepass.enable = true;

	# Services
	srv.syncthing.enable = true;


	# Fonts
	fonts.nerd-fonts-caskaydia-cove.enable = true;

	# Themes
	themes.godot.enable = true;

	# Tools
	tools.cli.fastfetch.enable = true;
	tools.cli.starship.enable = true;
	tools.cli.zoxide.enable = true;

	# Editors
	tools.editors.neovim = {
		enable = true;
		profile = "full";
		#debug.print-config = true;
		debug.print-plugins = true;
	};

	  default.homeDirectory = lib.mkDefault "/home/${config.default.username}";

	  # Home Manager needs a bit of information about you and the paths it should
	  # manage.
	  home.username = "${config.default.username}";
	  home.homeDirectory = "${config.default.homeDirectory}";

	  # This value determines the Home Manager release that your configuration is
	  # compatible with. This helps avoid breakage when a new Home Manager release
	  # introduces backwards incompatible changes.
	  #
	  # You should not change this value, even if you update Home Manager. If you do
	  # want to update the value, then make sure to first check the Home Manager
	  # release notes.
	  home.stateVersion = "25.11"; # Please read the comment before changing.


	  # Let Home Manager install and manage itself.
	  programs.home-manager.enable = true;
  };
}
