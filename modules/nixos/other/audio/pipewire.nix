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
    hardware.pulseaudio.enable = false; # Use Pipewire, the modern sound subsystem

    security.rtkit.enable = true; # Enable RealtimeKit for audio purposes

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };

    security.pam.loginLimits = [
      {
        domain = "@audio";
        item = "memlock";
        type = "-";
        value = "unlimited";
      }
      {
        domain = "@audio";
        item = "rtprio";
        type = "-";
        value = "99";
      }
      {
        domain = "@audio";
        item = "nofile";
        type = "soft";
        value = "99999";
      }
      {
        domain = "@audio";
        item = "nofile";
        type = "hard";
        value = "99999";
      }
    ];

    users.users."${config.host.user.name}".extraGroups = [ "audio" ];

    #
    # Bluetooth
    #
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
  };
}
