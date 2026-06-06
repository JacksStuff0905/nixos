{ pkgs }:
let
  lib = pkgs.lib;

  getHostServices =
    hosts:
    builtins.foldl' (sum: services: sum // services) { } (
      builtins.map convertServices (builtins.attrValues hosts)
    );

  convertServices =
    h:
    (builtins.mapAttrs (
      n: s:
      s
      // {
        domain = h.host.networking.domain;
        ip = h.host.networking.ip;
      }
    ) h.host.networking.publicServices);

  isHostNixOS = h: h.host.isNixOS;
in
{
  inherit getHostServices;
}
