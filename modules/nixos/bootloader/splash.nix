{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.bootloader.splash;
in
{
  options.bootloader.splash = {
    enable = lib.mkEnableOption "splash";
  };

  config = lib.mkIf cfg.enable {
    boot = {
      plymouth = {
        enable = true;
      };

      # Enable "Silent boot"
      consoleLogLevel = 3;
      initrd.verbose = false;
      kernelParams = [
        "quiet"
        "rd.udev.log_level=3"
        "rd.systemd.show_status=auto"
      ];
    };
  };
}
