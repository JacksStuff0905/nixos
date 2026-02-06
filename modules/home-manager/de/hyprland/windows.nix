{ config, lib, ... }:
let
  cfg = config.de.hyprland;
in
{
  config.wayland.windowManager.hyprland.settings = lib.mkIf cfg.enable {
    # Disable locking when in fullscreen
    windowrulev2 = [
      "idleinhibit fullscreen, class:^(*)$"
      "idleinhibit fullscreen, title:^(*)$"
      "idleinhibit fullscreen, fullscreen:1"
    ];

    # Ignore maximize requests from apps. You'll probably like this.
    windowrule = [
      "suppressevent maximize, class:.*"

      # Fix some dragging issues with XWayland
      "nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0"
    ];
  };
}
