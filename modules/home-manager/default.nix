{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

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
    sh.zsh.enable = lib.mkDefault true;
    sh.aliases.enable = lib.mkDefault true;
    sh.env-vars.enable = lib.mkDefault true;

    # Desktop apps
    apps.game-engines.godot.enable = lib.mkDefault true;
    apps.media.music.spotify.enable = lib.mkDefault true;
    apps.terminals.kitty.enable = lib.mkDefault true;
    apps.secrets.keepass.enable = lib.mkDefault true;
    apps.browsers.firefox.enable = lib.mkDefault true;

    # Services
    srv.syncthing.enable = lib.mkDefault true;

    # Fonts
    fonts.enable = lib.mkDefault true;

    # Themes
    themes.theme = lib.mkDefault {
      name = "godot";
      style = "dark";
    };

    # Tools
    tools.cli.fastfetch.enable = lib.mkDefault true;
    tools.cli.starship.enable = lib.mkDefault true;
    tools.cli.zoxide.enable = lib.mkDefault true;
    tools.cli.git.enable = lib.mkDefault true;
    tools.cli.nrun.enable = lib.mkDefault true;

    # Virtualization
    tools.virtualization.docker.enable = lib.mkDefault true;

    tools.editors.neovim.enable = lib.mkDefault true;

    # Allow unfree packages
    nixpkgs.config = lib.mkDefault {
      allowUnfree = true;
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
