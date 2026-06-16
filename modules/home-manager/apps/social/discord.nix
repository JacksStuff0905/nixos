{
  pkgs,
  config,
  lib,
  ...
}:

let
  cfg = config.apps.social.discord;
in
{
  options.apps.social.discord = {
    enable = lib.mkEnableOption "discord";
    clients = {
      discord = {
        enable = lib.mkEnableOption "official discord client";
      };
      vesktop = {
        enable = lib.mkEnableOption "vesktop client";
      };
    };
  };

  config = lib.mkIf config.apps.social.discord.enable {
    home.packages = with pkgs; lib.mkMerge [
      (lib.mkIf cfg.clients.discord.enable discord)
    ];

    programs.vesktop = lib.mkIf cfg.clients.vesktop.enable {
      enable = true;

      vencord.settings = {
        autoUpdate = true;
        autoUpdateNotification = true;
        notifyAboutUpdates = true;

        plugins = {
          ClearURLs.enabled = true;
          FixYoutubeEmbeds.enabled = true;
        };
      };
    };
  };
}
