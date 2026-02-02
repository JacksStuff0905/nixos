{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
	username = "jacek";
	homeDirectory = "/home/${username}";
in
{
  imports = [
    ../../modules/home-manager/apps
    ../../modules/home-manager/fonts
    ../../modules/home-manager/themes
    ../../modules/home-manager/tools
    ../../modules/home-manager/sh
    ../../modules/home-manager/srv
  ];

  config = {
    # Shell config
    sh.zsh.enable = true;
    sh.aliases.enable = true;
    sh.env-vars.enable = true;

    # Desktop apps
    apps.game-engines.godot.enable = false; # Godot will be enabled in project shells
    apps.media.music.spotify.enable = true;
    apps.terminals.kitty.enable = true;
    apps.secrets.keepass.enable = true;
    apps.browsers.firefox.enable = true;
    apps.launchers = {
      games = {
        lutris.enable = true;
        steam.enable = true;
      };
      bottles.enable = true;
    };

    # Services
    srv.syncthing.enable = true;

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

    # Virtualization
    tools.virtualization.docker.enable = true;

    tools.editors.neovim.enable = true;

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
