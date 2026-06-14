{
  config,
  lib,
  pkgs,
  util,
  inputs,
  ...
}:
let
  cfg = config.other.audio.musnix;
in
{
  imports = [
    inputs.musnix.nixosModules.musnix
  ];

  options.other.audio.musnix = {
    enable = lib.mkEnableOption "musnix";
  };

  config = lib.mkIf cfg.enable {
    musnix = {
      enable = true;
      rtcqs.enable = true;
    };

    security.pam.loginLimits = [
      {
        domain = "@audio";
        type = "soft";
        item = "nofile";
        value = "524288";
      }
      {
        domain = "@audio";
        type = "hard";
        item = "nofile";
        value = "524288";
      }
      {
        domain = "*";
        type = "soft";
        item = "nofile";
        value = "524288";
      }
      {
        domain = "*";
        type = "hard";
        item = "nofile";
        value = "524288";
      }
    ];

    users.users."${config.host.user.name}".extraGroups = [ "audio" ];
  };
}
