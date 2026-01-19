{
  config,
  lib,
  pkgs,
  inputs,
  system,
  ...
}:
let
  name = "main-www-server";

  cfg = config.virtualization.docker.stacks."${name}";

  nvim-profile = "full";
  nvim-package = inputs.nvim-nix.packages."${system}"."${nvim-profile}";

  nvim-password-hash = "$6$0G1ZyPZXuA.O8Cl9$awtXc9.QgL2lQTucAeZORZbB3p5JTFsjLNMu/2uTiim37RmLHFLyhSZvAPmKdSEknsU96xRFCmIzxl382CVWc1";

  nvim-www-image = pkgs.dockerTools.buildLayeredImage {
    name = "nvim-www";
    tag = "latest";

    # What packages go INSIDE the container?
    contents = [
      nvim-package
      pkgs.ttyd
      pkgs.cacert
      pkgs.bash
      pkgs.perl
      pkgs.coreutils # sleep
    ];

    extraCommands = "";

    config = {
      Cmd = [
        "ttyd"
        "--writable"
        "-t"
        "fontSize=18"
        "-t"
        ''fontFamily="Caskaydia Cove Nerd Font''
        "/bin/bash"
        "-c"
        (ttyd-auth-script nvim-password-hash "nvim /workspace" "echo \"Access denied\"; sleep 2; exit 1")
      ];

      ExposedPorts = {
        "7681" = { };
      };
    };
  };

  ttyd-auth-script = password-hash: success-cmd: failure-cmd: ''(
    echo "=== Authentication Required ==="
    read -s -p "Password: " PASSWORD_INPUT
    echo ""

    export PASS="$PASSWORD_INPUT"
    export HASH='${password-hash}'
    perl -e '
      exit(crypt($ENV{PASS}, $ENV{HASH}) eq $ENV{HASH} ? 0 : 1)
    '
    if [ $? -eq 0 ]; then
        exec ${success-cmd}
    else
        exec ${failure-cmd}
    fi
  )'';
in
{
  options.virtualization.docker.stacks."${name}" = {
    enable = lib.mkEnableOption "Enable ${name} docker stack";
  };

  config.virtualisation.oci-containers.containers = lib.mkIf cfg.enable {
    main-www-nginx = {
      image = "nginx:latest";
      ports = [
        "880:80"
        "4443:443"
      ];
      volumes = [
        "/data/stacks/remote/${name}/conf/nginx/:/etc/nginx/conf.d/"
        "/data/stacks/remote/${name}/src/:/data/www/"
      ];
    };

    main-www-nvim = {
      image = "nvim-www";
      imageFile = nvim-www-image;

      ports = [
        "7681:7681"
      ];

      environment = {
        TERM = "xterm-256color";
      };

      volumes = [
        "/data/stacks/remote/${name}/src/:/workspace"
      ];
    };
  };
}
