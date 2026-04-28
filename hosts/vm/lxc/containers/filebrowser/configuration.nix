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
    networking.enableIPv6 = false;

    fileSystems = {
      "/var/lib/immich" = {
        device = "${nasIP}:${nfsPath}/Files/Media";
        fsType = "nfs";
      };
    };

    srv.syncthing = {
      enable = true;

      id = "TKC4XOV-KRONILN-ZPSIOTP-EWAPE6Q-VMLSHLW-ERJFCA4-KQL3T7T-QXVMFQF";

      keySecret = ./secrets/syncthing-key.age;

      cert = ''
        -----BEGIN CERTIFICATE-----
        MIIBoDCCAVKgAwIBAgIJAKTTaHV1DAAqMAUGAytlcDBKMRIwEAYDVQQKEwlTeW5j
        dGhpbmcxIDAeBgNVBAsTF0F1dG9tYXRpY2FsbHkgR2VuZXJhdGVkMRIwEAYDVQQD
        EwlzeW5jdGhpbmcwHhcNMjYwNDI4MDAwMDAwWhcNNDYwNDIzMDAwMDAwWjBKMRIw
        EAYDVQQKEwlTeW5jdGhpbmcxIDAeBgNVBAsTF0F1dG9tYXRpY2FsbHkgR2VuZXJh
        dGVkMRIwEAYDVQQDEwlzeW5jdGhpbmcwKjAFBgMrZXADIQDU5/ZpNLWBJGM7IxkN
        mdaHxbm4rRCYHE/dY39jQLZLhKNVMFMwDgYDVR0PAQH/BAQDAgWgMB0GA1UdJQQW
        MBQGCCsGAQUFBwMBBggrBgEFBQcDAjAMBgNVHRMBAf8EAjAAMBQGA1UdEQQNMAuC
        CXN5bmN0aGluZzAFBgMrZXADQQBc5QtgLVy1V4+UFawwPHipZ8UndDPIhDRgtuSN
        896ei4FLI20JZfvsouSz8/HHR4AqET5g88iOvJGo+hZ/HcYN
        -----END CERTIFICATE-----
      '';
    };

    # Services
    srv.server = {
      filebrowser-quantum = {
        enable = true;
        openFirewall = false; # IP based firewall below
        secret.directory = ../../../../../secrets/filebrowser;

        samba = {
          enable = true;
          openFirewall = true;

          domain = "srv.lan";
          ldapHost = "192.168.10.7";

          secret.ldap-password = ../../../../../secrets/filebrowser/samba-ldap-password.age;
        };

        sources = {
          userDrives = "${nasIP}:${nfsPath}/Files/UserDrives";
          extra = [
            {
              path = "VM-Data";
              name = "vm data";
              defaultEnabled = false;
              mounts = {
                "Data" = {
                  remote = "${nasIP}:${nfsPath}/VM-Data/Data";
                  type = "nfs";
                };
                "Proxmox" = {
                  remote = "${nasIP}:${nfsPath}/VM-Data/Proxmox";
                  type = "nfs";
                };
              };
            }
            #"Backups" = "//${nasIP}/Backups";
            #"Files/Games" = "//${nasIP}/Games";
          ];
        };
      };

      immich = {
        enable = false;
        openFirewall = true;
        secret.directory = ../../../../../secrets/filebrowser;
        group = {
          name = "filebrowser";
        };
      };
    };

    networking.firewall = {
      enable = true;
      extraCommands = ''
        # Block external access to FileBrowser port
        iptables -A INPUT -p tcp --dport ${toString config.srv.server.filebrowser-quantum.port} -s 192.168.10.9 -j ACCEPT
        iptables -A INPUT -p tcp --dport ${toString config.srv.server.filebrowser-quantum.port} -j DROP
      '';

      extraStopCommands = ''
        iptables -D INPUT -p tcp --dport ${toString config.srv.server.filebrowser-quantum.port} -s 192.168.10.9 -j ACCEPT 2>/dev/null || true
        iptables -D INPUT -p tcp --dport ${toString config.srv.server.filebrowser-quantum.port} -j DROP 2>/dev/null || true
      '';
    };

    # Allow unfree packages
    nixpkgs.config = {
      allowUnfree = true;
    };
  };
}
