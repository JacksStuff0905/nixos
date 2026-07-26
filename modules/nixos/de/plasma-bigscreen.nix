{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  cfg = config.de.plasma-bigscreen;

  system = "x86_64-linux";
  master-pkgs = import inputs.nixpkgs-master { inherit system; };
in
{
  options.de.plasma-bigscreen = {
    enable = lib.mkEnableOption "Enable plasma-bigscreen module";
  };

  config = lib.mkIf cfg.enable {
    services.xserver.enable = true;

    services.desktopManager.plasma6.enable = true;

    environment.systemPackages = with master-pkgs.kdePackages; [
      plasma-bigscreen
      plasma-nano
      plasma-nm
      plasma-pa
      milou
      kdeconnect-kde
      kscreen
      plasma-settings
    ];

    environment.sessionVariables = {
      QT_PLUGIN_PATH = ["${master-pkgs.kdePackages.plasma-bigscreen}/lib/qt-6/plugins"];
      QML2_IMPORT_PATH = ["${master-pkgs.kdePackages.plasma-bigscreen}/lib/qt-6/qml"];
    };

    programs.ssh.askPassword = lib.mkForce "${pkgs.x11_ssh_askpass}/libexec/x11-ssh-askpass";

    services.displayManager.sessionPackages = [
      master-pkgs.kdePackages.plasma-bigscreen
    ];
  };
}
