# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, inputs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      inputs.home-manager.nixosModules.default
      ../../modules/nixos/bootloader
      ../../modules/nixos/dev-utils
      ../../modules/nixos/virtualization
      ../../modules/nixos/sh
      ../../modules/nixos/de
      ../../modules/nixos/dm
    ];


  networking.hostName = "JacekMacbook";
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
  dm.gdm.enable = true;

  # Users
	users.groups.nixos = {};

	users.users.jacek = {
		isNormalUser = true;
		extraGroups = [ "wheel" "nixos" ];
		shell = pkgs.zsh;
	};

  # Virtualization
  virtualization.docker = {
    enable = true;	
    users = ["jacek"];
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
			"jacek" = import ./home.nix;
		};
	};

  system.stateVersion = "25.11";
}
