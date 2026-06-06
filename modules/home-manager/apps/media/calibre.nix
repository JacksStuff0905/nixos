{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.apps.media.calibre;
in
{
  options.apps.media.calibre = {
    enable = lib.mkEnableOption "Enable calibre module";
  };

  config = lib.mkIf config.apps.media.calibre.enable {
    home.packages = with pkgs; [
      calibre
    ];
  };
}
