# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  config,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    inputs.home-manager.nixosModules.default
    ../../modules/nixos/bootloader
    ../../modules/nixos/dev-utils
    ../../modules/nixos/virtualization
    ../../modules/nixos/sh
    ../../modules/nixos/de
    ../../modules/nixos/dm
    ../../modules/nixos/srv
  ];

  host = {
    username = "jacek";
    hostName = "jacek-macbook";

    isProduction = true;
    isDesktop = true;
  };

  networking.hostName = "${config.host.hostName}";
  programs.zsh.enable = true;

  # Bootloader
  bootloader.grub.enable = true;

  # Filesystems
  boot.supportedFilesystems = [ "ntfs" ];

  # Developer utilities
  dev-utils.gnumake.enable = true;
  dev-utils.neovim.enable = false;

  # GUI
  de.gnome.enable = true;
  de.hyprland.enable = true;
  de.dwl.enable = false;
  dm.gdm.enable = true;

  # Users
  users.groups.nixos = { };

  users.users."${config.host.username}" = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "nixos"
    ];
    home = "${config.host.home}";
    createHome = true;
    shell = pkgs.zsh;
  };

  # Virtualization
  virtualization.docker = {
    enable = true;
    users = [ "${config.host.username}" ];
  };

  # Shell config
  sh.aliases.enable = true;
  sh.zsh.enable = true;

  # Services
  srv.ssh.enable = false;
  srv.printing.enable = true;
  srv.syncthing = {
    enable = true;

    id = "";

    keySecret = ./secrets/syncthing-key.age;

    cert = '''';
  };

  srv.lamp-test.enable = true;
  srv.lamp-test.documentRoot = "/var/www/lamp-test";
  srv.lamp-test.user = "${config.host.username}";

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Allow unfree packages
  nixpkgs.config = {
    allowUnfree = true;
  };

  # Enable networking
  networking.networkmanager.enable = true;

  # Enable flakes
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Use beta cache
  nix.settings.substituters = [ "https://aseipp-nix-cache.global.ssl.fastly.net" ];

  # Set your time zone.
  time.timeZone = "Europe/Warsaw";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "pl_PL.UTF-8";
    LC_IDENTIFICATION = "pl_PL.UTF-8";
    LC_MEASUREMENT = "pl_PL.UTF-8";
    LC_MONETARY = "pl_PL.UTF-8";
    LC_NAME = "pl_PL.UTF-8";
    LC_NUMERIC = "pl_PL.UTF-8";
    LC_PAPER = "pl_PL.UTF-8";
    LC_TELEPHONE = "pl_PL.UTF-8";
    LC_TIME = "pl_PL.UTF-8";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "pl";
    variant = "";
  };

  # Configure console keymap
  console.keyMap = "pl2";

  # Garbage collect
  nix.gc.automatic = true;

  # HM integration
  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users = {
      "${config.host.username}" = import ./home.nix;
    };
  };

  system.stateVersion = "25.11";
}
