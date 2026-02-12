{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  imports = [
    inputs.nvim-nix.nixosModules.default
  ];

  config = {
    boot.isContainer = true;

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

    # Console setup (Proxmox)
    systemd.services."getty@".enable = false;
    systemd.services."autovt@".enable = false;
    systemd.services."console-getty".enable = true;

    # Enable flakes
    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    # Enable networking
    networking.networkmanager.enable = true;
    networking.firewall.enable = true;

    networking.enableIPv6 = false;
    nix.settings.connect-timeout = 5;
    nix.settings.stalled-download-timeout = 5;

    # Shell config
    sh.aliases.enable = true;
    sh.zsh.enable = true;

    # Services
    srv.ssh.enable = true;

    # Developer utilities
    dev-utils.neovim.enable = false;
    programs.nvim-nix = {
      enable = true;
      profile = "basic";
    };

    users.users.root = {
      extraGroups = [
        "wheel"
        "nixos"
      ];
      shell = pkgs.zsh;
    };

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

    # Configure console keymap
    console.keyMap = "pl2";

    # Garbage collect
    nix.gc.automatic = true;

    system.stateVersion = "25.11";
  };
}
