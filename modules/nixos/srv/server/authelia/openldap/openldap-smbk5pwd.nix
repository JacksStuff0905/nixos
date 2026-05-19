{ pkgs, ... }:
let
  openldapWithSmbk5pwd = pkgs.openldap.overrideAttrs (old: {
    # smbk5pwd needs OpenSSL for NT hash generation
    buildInputs = (old.buildInputs or [ ]) ++ [ pkgs.openssl ];

    # Build the smbk5pwd contrib module and install it into lib/modules
    postBuild = (old.postBuild or "") + ''
      echo "=== Building smbk5pwd contrib module (Samba-only) ==="

      # Enter the contrib module directory
      cd contrib/slapd-modules/smbk5pwd

      # Build shared module. Use same compiler/flags as main build.
      # DO_SAMBA = Samba-only (no Kerberos). This is the common case.
      $CC -shared -fPIC \
        -DDO_SAMBA \
        -I../../../include \
        -I../../../servers/slapd \
        -I../../../ \
        -I${pkgs.openssl.dev}/include \
        -L${pkgs.openssl.out}/lib \
        -lssl -lcrypto \
        -o smbk5pwd.so \
        smbk5pwd.c

      cd ../../..

      echo "=== smbk5pwd build done ==="
      ls -la contrib/slapd-modules/smbk5pwd/smbk5pwd.so
    '';

    postInstall = (old.postInstall or "") + ''
      echo "=== Installing smbk5pwd.so into lib/modules ==="
      mkdir -p $out/lib/modules

      if [ -f contrib/slapd-modules/smbk5pwd/smbk5pwd.so ]; then
        install -m 755 contrib/slapd-modules/smbk5pwd/smbk5pwd.so \
          $out/lib/modules/smbk5pwd.so
        echo "Installed: $out/lib/modules/smbk5pwd.so"
      else
        echo "ERROR: smbk5pwd.so not found after build!"
        exit 1
      fi

      # Sanity check
      file $out/lib/modules/smbk5pwd.so || true
    '';
  });
in
openldapWithSmbk5pwd
