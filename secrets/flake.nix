{
  description = "Agenix secret configuration shell";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    agenix.url = "github:ryantm/agenix";
  };

  outputs =
    {
      self,
      nixpkgs,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      lib = pkgs.lib;
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [
          pkgs.openssl
          inputs.agenix.packages.${system}.default
        ];

        shellHook = ''
          echo "Agenix configuration env loaded."
          alias gen-secret="openssl rand -base64 32 | tr -d '\n'"
          function write-secret {
            echo -n "$1" | agenix -e "$2"
          }
          alias encrypt-oidc-secret="nix-shell -p authelia --run \"authelia crypto hash generate pbkdf2 --random.length 72\""
          echo "Use \`gen-secret\` to generate a random secret string"
          echo "Use \`write-secret [secret] [file]\` to write a secret to a file (without newline)"
          echo "Use \`encrypt-oidc-secret\` to hash/encrypt an oidc secret"
        '';
      };
    };
}
