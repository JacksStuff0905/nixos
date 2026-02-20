{ lib, authentikLib }:

{
  oauth2 = import ./oauth2.nix { inherit lib authentikLib; };
  saml = import ./saml.nix { inherit lib authentikLib; };
  proxy = import ./proxy.nix { inherit lib authentikLib; };
  ldap = import ./ldap.nix { inherit lib authentikLib; };

  getGenerator =
    type:
    {
      oauth2 = import ./oauth2.nix { inherit lib authentikLib; };
      saml = import ./saml.nix { inherit lib authentikLib; };
      proxy = import ./proxy.nix { inherit lib authentikLib; };
      ldap = import ./ldap.nix { inherit lib authentikLib; };
    }
    .${type} or (throw "Unknown provider type: ${type}");
}
