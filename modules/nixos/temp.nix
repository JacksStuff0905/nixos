{config, pkgs, inputs, ...}:

{
	users.groups.nixos = {};

	programs.zsh.enable = true;

	users.users.jacek = {
		isNormalUser = true;
		extraGroups = [ "wheel" "nixos" ];
		shell = pkgs.zsh;
	};

	programs.hyprland = {
		enable = true;
		xwayland.enable = true;
		withUWSM = true;
	};

	services.xserver.enable = true;

	services.displayManager.gdm.enable = true;
	services.desktopManager.gnome.enable = true;

	systemd.defaultUnit = "graphical.target";

	nix.gc.automatic = true;


	home-manager = {
		extraSpecialArgs = {inherit inputs;};
		users = {
			"jacek" = import ../../hosts/macbook/home.nix;
		};
	};
}
