# modules/authentik-blueprints/types/application.nix
{ lib, authentikLib }:

with lib;

let
  providerType = import ./provider.nix { inherit lib; };
  accessControlType = import ./access-control.nix { inherit lib; };

in
types.submodule (
  { name, config, ... }:
  {
    options = {
      enable = mkEnableOption "this application" // {
        default = true;
      };

      name = mkOption {
        type = types.str;
        default = name;
        description = "Application display name";
      };

      slug = mkOption {
        type = types.strMatching "^[a-z0-9-]+$";
        default = lib.toLower (builtins.replaceStrings [ " " "_" ] [ "-" "-" ] name);
        description = "Application slug (URL-safe identifier)";
      };

      description = mkOption {
        type = types.str;
        default = "";
        description = "Application description";
      };

      group = mkOption {
        type = types.str;
        default = "";
        description = "Application group for organization";
      };

      icon = mkOption {
        type = types.str;
        default = "";
        description = "Application icon URL";
      };

      launchUrl = mkOption {
        type = types.str;
        default = "";
        description = "Application launch URL";
      };

      openInNewTab = mkOption {
        type = types.bool;
        default = true;
        description = "Open application in new tab";
      };

      provider = mkOption {
        type = providerType;
        default = { };
        description = "Provider configuration";
      };

      accessControl = mkOption {
        type = accessControlType;
        default = { };
        description = "Access control settings";
      };

      outpost = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Outpost name to add this application to (for proxy/ldap providers)";
      };
    };
  }
)
