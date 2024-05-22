{
  description = "Bedrock Bit Vector Library";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/release-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, flake-utils, nixpkgs, ... }:
    let
      coqBbvPkg = { lib, mkCoqDerivation, coq, version ? null }: with lib; mkCoqDerivation rec {
        pname = "coq-bbv";
        inherit version;
        defaultVersion = with versions; switch [ coq.version ] [
          { cases = [ (range "8.16" "8.19") ]; out = "1.5"; }
          { cases = [ (range "8.14" "8.15") ]; out = "1.4"; }
          { cases = [ (range "8.7"  "8.13") ]; out = "1.3"; }
        ] null;

        opam-name = "coq-bbv";

        release = {
          "1.5".src = lib.cleanSourceWith {
            src = lib.cleanSource ./.;
            filter = let inherit (lib) hasSuffix; in
              path: type:
                (! hasSuffix ".gitignore" path)
                && (! hasSuffix "flake.nix" path)
                && (! hasSuffix "flake.lock" path)
                && (! hasSuffix "_build" path);
          };
          "1.4".rev = "v1.4";
          "1.3".rev = "v1.3";
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
          devShells.default = packages.default;

          packages = rec {
            coq8_18-coq-bbv = pkgs.coqPackages_8_18.coq-bbv;
            coq8_19-coq-bbv = pkgs.coqPackages_8_19.coq-bbv;
            default = coq8_19-coq-bbv;
          };
        }) // {
      overlays.default = final: prev:
        (nixpkgs.lib.mapAttrs
          (_: scope:
            scope.overrideScope (self: _: {
              coq-bbv = self.callPackage coqBbvPkg { };
            })
          )
          {
            inherit (prev) coqPackages_8_18 coqPackages_8_19;
          }
        );
    };
}
