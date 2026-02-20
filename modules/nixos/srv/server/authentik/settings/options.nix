{
  config,
  lib,
  pkgs,
  authentikTypes,
  ...
}:

with lib;

let
  ownershipTypes = import ./types/ownership.nix { inherit lib; };

in
{
  options.srv.server.authentik = {
    applications = mkOption {
      type = types.attrsOf authentikTypes.application;
      default = { };
      description = "Application definitions";
    };

    blueprints = mkOption {
      type = types.attrsOf authentikTypes.blueprint;
      default = { };
      description = "Custom blueprint definitions";
    };

    users = mkOption {
      type = types.attrsOf authentikTypes.user;
      default = { };
      description = "User definitions";
    };

    groups = mkOption {
      type = types.attrsOf authentikTypes.group;
      default = { };
      description = "Group definitions";
    };

    outposts = mkOption {
      type = types.attrsOf authentikTypes.outpost;
      default = { };
      description = "Outpost definitions";
      example = literalExpression ''
        {
          proxy-outpost = {
            type = "proxy";
            config = {
              authentik_host = "https://auth.example.com";
            };
          };
          ldap-outpost = {
            type = "ldap";
          };
        }
      '';
    };

    generatedPath = mkOption {
      type = types.path;
      readOnly = true;
      description = "Path to generated blueprints (read-only)";
    };

    outputDir = mkOption {
      type = types.str;
      default = "/var/lib/authentik/blueprints/custom";
      description = "Directory where blueprints are deployed";
    };

    user = mkOption {
      type = types.nullOr ownershipTypes.userOrUid;
      default = null;
      description = "Owner of blueprint files (name or UID)";
    };

    group = mkOption {
      type = types.nullOr ownershipTypes.groupOrGid;
      default = null;
      description = "Group of blueprint files (name or GID)";
    };
  };
}
