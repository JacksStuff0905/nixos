{
  config,
  pkgs,
  lib,
  inputs,
  modulesPath,
  ...
}:
{
  imports = [
    inputs.nvim-nix.nixosModules.default
    (modulesPath + "/virtualisation/proxmox-lxc.nix")
    ../../../modules/nixos/dev-utils
    ../../../modules/nixos/sh
    ../../../modules/nixos/srv
  ];


  # ENABLE COMMANDS
  # ======================================================
  # export PATH=/run/current-system/sw/bin:$PATH
  # ======================================================
  # MOUNT DATA DIR IN PROXMOX
  # ======================================================
  # pct set <vmid> -mp0 /mnt/pve/data-slow/container-name,mp=/mount/point
  # ======================================================

  config = {
    # LXC specific config
    boot.isContainer = true;

    # Enable flakes
    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    # Supress systemd units that don't work because of LXC
    systemd.suppressedSystemUnits = [
      "dev-mqueue.mount"
      "sys-kernel-debug.mount"
      "sys-fs-fuse-connections.mount"
    ];

    # start tty1 on serial console
    systemd.services."getty@tty1" = {
      enable = true;
      wantedBy = [ "getty.target" ]; # to start at boot
      serviceConfig.Restart = "always"; # restart when session is closed
      serviceConfig.ExecStart = [
        ""
        "@${pkgs.util-linux}/sbin/agetty agetty --login-program ${config.services.getty.loginProgram} --noclear --keep-baud %I 115200,38400,9600 $TERM"
      ];
    };

    environment.systemPackages = with pkgs; [
      binutils
    ];

    # Proxmox
    nix.settings = {
      sandbox = false;
    };
    proxmoxLXC = {
      manageNetwork = false;
      privileged = true;
      manageHostName = true;
    };
    security.pam.services.sshd.allowNullPassword = true;
    services.fstrim.enable = false; # Let Proxmox host handle fstrim
    services.openssh = {
      enable = true;
      openFirewall = true;
      settings = {
        PermitRootLogin = "yes";
        PasswordAuthentication = true;
        PermitEmptyPasswords = "yes";
      };
    };

    # Shell config
    sh.aliases.enable = true;
    sh.zsh.enable = true;

    # Services
    srv.ssh = {
      enable = true;
      enableRoot = true;
    };

    # Developer utilities
    programs.nvim-nix = {
      enable = true;
      profile = "basic";
    };

    dev-utils.git.enable = true;

    users.users.root = {
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

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

    system.stateVersion = "25.11";
  };
}
