{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.tools.virtualization.distrobox;
in
{
  options.tools.virtualization.distrobox = {
    enable = lib.mkEnableOption "distrobox";
  };

  config = lib.mkIf config.tools.virtualization.distrobox.enable {
    programs.distrobox = {
      enable = true;
      containers = {
        ue5 = {
          entry = true;
          additional_packages = "alsa-lib pango libxkbcommon libgbm libXrandr libXdamage libXcomposite-devel at-spi2-atk libxml2-devel nss.x86_64";
          home = "/tmp/distrobox-home/ue5";
          image = "rockylinux:8";
          volume = "/opt:/opt";
        };
      };
    };
  };
}
