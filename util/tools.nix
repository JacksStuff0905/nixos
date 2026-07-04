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
        ip = (ip-nix.splitIp h.host.networking.ip).ip;
      }
    ) h.host.networking.publicServices);

  isHostNixOS = h: h.host.isNixOS;

  pow =
    base: exp:
    if exp == 0 then
      1
    else if exp == 1 then
      base
    else
      let
        half = pow base (exp / 2);
      in
      if (builtins.bitAnd exp 1) == 0 then half * half else half * half * base;

  # https://github.com/infinisil/system/blob/f41c1437aa146fcfd038694d92a077a02f01f142/deploy/lib/ip.nix
  ip-nix = rec {
    parseIp = str: map lib.toInt (builtins.match "([0-9]+)\\.([0-9]+)\\.([0-9]+)\\.([0-9]+)" str);
    prettyIp = lib.concatMapStringsSep "." toString;

    cidrToMask =
      let
        # Generate a partial mask for an integer from 0 to 7
        #   part 1 = 128
        #   part 7 = 254
        part = n: if n == 0 then 0 else part (n - 1) / 2 + 128;
      in
      cidr:
      let
        # How many initial parts of the mask are full (=255)
        fullParts = cidr / 8;
      in
      lib.genList (
        i:
        # Fill up initial full parts
        if i < fullParts then
          255
        # If we're above the first non-full part, fill with 0
        else if fullParts < i then
          0
        # First non-full part generation
        else
          part (lib.mod cidr 8)
      ) 4;

    getSubnet =
      str:
      let
        splitParts = builtins.split "/" str;
        givenIp = parseIp (lib.elemAt splitParts 0);
        cidr = lib.toInt (lib.elemAt splitParts 2);
        mask = cidrToMask cidr;
        baseIp = lib.zipListsWith lib.bitAnd givenIp mask;
      in
      {
        inherit
          baseIp
          mask
          cidr
          ;
        givenIp = baseIp;
      };

    parseSubnet =
      subnet:
      let
        range = {
          from = subnet.baseIp;
          to = lib.zipListsWith (b: m: 255 - m + b) subnet.baseIp subnet.mask;
        };
        check = ip: subnet.baseIp == lib.zipListsWith (b: m: lib.bitAnd b m) ip subnet.mask;
        warn =
          if subnet.baseIp == subnet.givenIp then
            lib.id
          else
            lib.warn (
              "subnet ${prettyIp subnet.givenIp}/${toString subnet.cidr} has a too specific base address ${prettyIp subnet.givenIp}, "
              + "which will get masked to ${prettyIp subnet.baseIp}, which should be used instead"
            );
      in
      warn {
        inherit (subnet)
          baseIp
          cidr
          mask
          ;
        inherit
          range
          check
          ;
        subnet = "${prettyIp subnet.baseIp}/${toString subnet.cidr}";
      };

    mapIp = oper: ip: builtins.map (v: (oper v)) ip;

    zipIps =
      oper: ipa: ipb:
      lib.zipListsWith (a: b: (oper a b)) ipa ipb;

    splitIp =
      ip:
      let
        split = builtins.split "/" ip;
      in
      {
        ip = builtins.elemAt split 0;
        cidr = builtins.elemAt split 2;
      };
  };

  lerp =
    a: b: t:
    a + t * (b - a);
in
{
  inherit
    getHostServices
    isHostNixOS
    pow
    ip-nix
    lerp
    ;
}
