# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./host.nix
    inputs.home-manager.nixosModules.default
    ../../modules/nixos/bootloader
    ../../modules/nixos/dev-utils
    ../../modules/nixos/virtualization
    ../../modules/nixos/sh
    ../../modules/nixos/de
    ../../modules/nixos/dm
    ../../modules/nixos/srv
    ../../modules/nixos/other
  ];

  networking.hostName = config.host.hostName;
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

  # Other
  other.apps.steam.enable = true;

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
  virtualization = {
    virt-manager = {
      enable = true;
      users = [ "${config.host.username}" ];
    };

    docker = {
      enable = true;
      users = [ "${config.host.username}" ];
    };
  };

  # Shell config
  sh.aliases.enable = true;
  sh.zsh.enable = true;

  # Services
  srv.ssh.enable = true;
  srv.printing.enable = true;

  srv.syncthing = {
    enable = true;

    id = "5XL6TVD-YLV522Y-HF3QXXN-X6NVRC7-E7SBMBY-4OAADUC-BHPR6KM-5YWUMQF";

    keySecret = ./secrets/syncthing-key.age;

    devices.extraDevices = {
      "jacek S21FE" = {
        id = "MVRIPLU-SETOKVI-BEDFUGD-RU4BQRE-H3LCJTZ-6VLJSRD-ETOA2U2-JEYHFAS";
      };
    };

    cert = ''
      -----BEGIN CERTIFICATE-----
      MIIBnzCCAVGgAwIBAgIIIceivbfc9O0wBQYDK2VwMEoxEjAQBgNVBAoTCVN5bmN0
      aGluZzEgMB4GA1UECxMXQXV0b21hdGljYWxseSBHZW5lcmF0ZWQxEjAQBgNVBAMT
      CXN5bmN0aGluZzAeFw0yNjA0MjYwMDAwMDBaFw00NjA0MjEwMDAwMDBaMEoxEjAQ
      BgNVBAoTCVN5bmN0aGluZzEgMB4GA1UECxMXQXV0b21hdGljYWxseSBHZW5lcmF0
      ZWQxEjAQBgNVBAMTCXN5bmN0aGluZzAqMAUGAytlcAMhAPtq35PFWrxgaMnlQI/i
      dYrkqAmvV1JXa2a3uJ7J/7kzo1UwUzAOBgNVHQ8BAf8EBAMCBaAwHQYDVR0lBBYw
      FAYIKwYBBQUHAwEGCCsGAQUFBwMCMAwGA1UdEwEB/wQCMAAwFAYDVR0RBA0wC4IJ
      c3luY3RoaW5nMAUGAytlcANBAH6gdFW0P9guj1bLWbSC56bKoQDltDHILB9irIAp
      OSOwN38Q16dQbSSNlHCJkwoaLFc7bmoQuvI0/EtJOgd4QQQ=
      -----END CERTIFICATE-----'';
  };

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
