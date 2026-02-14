{
  config,
  lib,
  pkgs,
  ...
}:
let
  name = "nginx";

  cfg = config.srv.server."${name}";

  mkCert = domain: ''
    CERT_DIR="/var/lib/nginx/certs"
    if [ ! -f "$CERT_DIR/${domain}/key" ]; then
      mkdir -p "$CERT_DIR"
      ${pkgs.openssl}/bin/openssl req -x509 -nodes -days 3650 \
        -newkey rsa:2048 \
        -keyout "$CERT_DIR/${domain}/key" \
        -out "$CERT_DIR/${domain}/crt" \
        -subj "/CN=*.${domain}" \
        -addext "subjectAltName=DNS:*.${domain},DNS:${domain}"
      chmod 600 "$CERT_DIR"/*.key
    fi
  '';
in
{
  options.srv.server."${name}" = {
    enable = lib.mkEnableOption "Enable ${name}";
    virtualHosts = lib.mkOption {
      type = lib.types.attrs;
      default = { };
    };
    certificates = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
  };

  config = lib.mkIf cfg.enable {
    system.activationScripts.generateSSLCerts =
      builtins.concatStringsSep "\n" (builtins.map mkCert cfg.certificates);

    services.nginx = {
      enable = true;

      mapHashMaxSize = 512;

      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;

      # Global settings for large uploads (Calibre, etc.)
      clientMaxBodySize = "0";

      virtualHosts = cfg.virtualHosts;
    };

    # Open firewall
    networking.firewall.allowedTCPPorts = [
      80
      443
    ];
  };
}
