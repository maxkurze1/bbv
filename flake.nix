{
  description = "Bedrock Bit Vector Library";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/release-23.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, flake-utils, nixpkgs, ... }:
    let
      coqBbvPkg = { lib, mkCoqDerivation, coq }: mkCoqDerivation rec {
        pname = "coq-bbv";
        defaultVersion = "0.0.1";

        opam-name = "coq-bbv";

        release."0.0.1" = {
          version = "0.0.1";
          src = lib.const (lib.cleanSourceWith {
            src = lib.cleanSource ./.;
            filter = let inherit (lib) hasSuffix; in
              path: type:
                (! hasSuffix ".gitignore" path)
                && (! hasSuffix "flake.nix" path)
                && (! hasSuffix "flake.lock" path)
                && (! hasSuffix "_build" path);
          });
        };
      };
    in
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ self.overlays.default ];
          };
        in
        rec {
          devShells.default = packages.default.overrideAttrs (_: {
            shellHook = ''
              [[ -v SHELL ]] && exec "$SHELL"
            '';
          });

          packages = rec {
            coq8_18-coq-bbv = pkgs.coqPackages_8_18.coq-bbv;
            default = coq8_18-coq-bbv;
          };
        }) // {
      overlays.default = final: prev:
        (nixpkgs.lib.mapAttrs
          (_: scope:
            scope.overrideScope' (self: _: {
              coq-bbv = self.callPackage coqBbvPkg { };
            })
          )
          {
            inherit (prev) coqPackages_8_18;
          }
        );
    };
}
