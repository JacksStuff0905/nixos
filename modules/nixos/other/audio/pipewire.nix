{
  config,
  lib,
  pkgs,
  util,
  ...
}:
let
  cfg = config.other.audio.pipewire;
in
{
  options.other.audio.pipewire = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    services.pulseaudio.enable = false; # Use Pipewire, the modern sound subsystem

    security.rtkit.enable = true; # Enable RealtimeKit for audio purposes

    security.pam.loginLimits = [
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

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };

    #
    # Bluetooth
    #
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
  };
}
