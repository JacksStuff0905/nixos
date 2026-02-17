{
  config,
  pkgs,
  inputs,
  ...
}:

let
  main-user = "jacek";
in
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    inputs.nvim-nix.nixosModules.default
    ../../../modules/nixos/bootloader
    ../../../modules/nixos/dev-utils
    ../../../modules/nixos/sh
    ../../../modules/nixos/srv
    ../../../modules/nixos/virtualization
  ];

  networking.hostName = "vm-router";
  programs.zsh.enable = true;

  # Bootloader
  bootloader.grub.enable = true;

  # Proxmox guest
  virtualization.proxmox.guest.enable = true;

  # Services
  srv = {
    ssh = {
      enable = true;
      enableRoot = true;
    };

    server.router = {
      enable = true;
      interfaces = {
        wan = {
          name = "ens18";
          dhcp.client = true;
        };
        lan = {
          name = "ens19";
          address = {
            enable = true;
            cidr = "192.168.10.1/24";
          };
        };
      };
    };
  };

  # Developer utilities
  programs.nvim-nix = {
    enable = true;
    profile = "basic";
  };

  dev-utils.git.enable = true;

  # Users
  users.groups.nixos = { };

  users.users.${main-user} = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "nixos"
    ];
    shell = pkgs.zsh;
  };

  # Shell config
  sh.aliases.enable = true;
  sh.zsh.enable = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Allow unfree packages
  nixpkgs.config = {
    allowUnfree = true;
  };

  # Enable IP forwarding
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  # Enable flakes
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

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

  system.stateVersion = "25.11";
}
