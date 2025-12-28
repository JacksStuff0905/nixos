{ config, pkgs, lib, inputs, ... }:

{
	imports = [
	      ../../modules/nixos/temp.nix
	      ../../modules/nixos/bootloader
	      ../../modules/nixos/dev-utils
	];


  config = {
	  bootloader.grub.enable = true;

	  # Developer utilities
	  dev-utils.gnumake.enable = true;
	  dev-utils.neovim.enable = true;	



	  # Use latest kernel.
	  boot.kernelPackages = pkgs.linuxPackages_latest;

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
	};
}
