{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
	username = "docker";
	homeDirectory = "/home/${username}";
in
{
  imports = [
    ../../../modules/home-manager/apps
    ../../../modules/home-manager/fonts
    ../../../modules/home-manager/themes
    ../../../modules/home-manager/tools
    ../../../modules/home-manager/sh
    ../../../modules/home-manager/srv
  ];

  config = {
    # Shell config
    sh.zsh.enable = true;
    sh.aliases.enable = true;
    sh.env-vars.enable = true;

    # Fonts
    fonts.enable = true;

    # Themes
    themes.theme = {
      name = "godot";
      style = "dark";
    };

    # Tools
    tools.cli.fastfetch.enable = true;
    tools.cli.starship.enable = true;
    tools.cli.zoxide.enable = true;
    tools.cli.git.enable = true;
    tools.cli.nrun.enable = true;

    tools.editors.neovim = {
      enable = true;
      profile = "basic";
    };

    # Allow unfree packages
    nixpkgs.config = {
      allowUnfree = true;
    };

    # Home Manager needs a bit of information about you and the paths it should
    # manage.
    home.username = "${username}";
    home.homeDirectory = "${homeDirectory}";

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
