{ config, pkgs, inputs, ... }:

let
	main-user = "docker";
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      inputs.home-manager.nixosModules.default
      ../../../modules/nixos/bootloader
      ../../../modules/nixos/dev-utils
      ../../../modules/nixos/sh
      ../../../modules/nixos/de
      ../../../modules/nixos/dm
      ../../../modules/nixos/srv
      ../../../modules/nixos/virtualization
      ./stacks
    ];


  networking.hostName = "DockerVM";
  programs.zsh.enable = true;

  # Bootloader
  bootloader.grub.enable = true;

  # Filesystems
  boot.supportedFilesystems = [ "ntfs" ];

  # Services
  srv.ssh.enable = true;

  # Developer utilities
  dev-utils.gnumake.enable = true;
  dev-utils.neovim.enable = false;	

  # Users
	users.groups.nixos = {};

	users.users.${main-user} = {
		isNormalUser = true;
		extraGroups = [ "wheel" "nixos" ];
		shell = pkgs.zsh;
	};

  # Virtualization
  virtualization.docker = {
    enable = true;	
    users = ["${main-user}"];
  };

  # Docker stacks
  virtualization.docker.stacks = {
    nginx-proxy-manager.enable = true;
    calibre.enable = true;
    main-www-server.enable = true;
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

  # Enable networking
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];


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
		extraSpecialArgs = {inherit inputs;};
		users = {
			"${main-user}" = import ./home.nix;
		};
	};

  system.stateVersion = "25.11";
}
