{
  config,
  pkgs,
  inputs,
  ...
}:
let
  nasIP = "192.168.10.6";
  nfsPath = "/mnt/Main4TB";
in
{
  imports = [
    ../../base-lxc.nix
    ../../../../../modules/nixos/srv
  ];

  config = {
    networking.hostName = "ct-filebrowser";

    # Services
    srv.server = {
      filebrowser = {
        enable = true;
        openFirewall = false; # IP based firewall below
        secretFile = ./secrets/filebrowser-secret.age;
        mounts = {
          nfs = {
            "VM-Data/Data" = "${nasIP}:${nfsPath}/VM-Data/Data";
            "VM-Data/Proxmox" = "${nasIP}:${nfsPath}/VM-Data/Proxmox";
          };
          smb = {
            #"Backups" = "//${nasIP}/Backups";
            #"Files/Games" = "//${nasIP}/Games";
          };
        };
      };
    };

    networking.firewall = {
      enable = true;
      extraCommands = ''
        # Block external access to FileBrowser port
        iptables -A INPUT -p tcp --dport ${toString config.srv.server.filebrowser.port} -s 192.168.10.9 -j ACCEPT
        iptables -A INPUT -p tcp --dport ${toString config.srv.server.filebrowser.port} -j DROP
      '';

      extraStopCommands = ''
        iptables -D INPUT -p tcp --dport ${toString config.srv.server.filebrowser.port} -s 192.168.10.9 -j ACCEPT 2>/dev/null || true
        iptables -D INPUT -p tcp --dport ${toString config.srv.server.filebrowser.port} -j DROP 2>/dev/null || true
      '';
    };

    # Allow unfree packages
    nixpkgs.config = {
      allowUnfree = true;
    };
  };
}
