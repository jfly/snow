let
  mkHost = cfg: system:
    let
      pkgs = (import ./sources.nix).pkgs {
        inherit system;
        overlays = import ./overlays;
        config.allowUnfreePredicate = pkg: builtins.elem (pkgs.lib.getName pkg) [
          "parsec"
        ];
      };
    in
      { lib, ... }: {
        imports = [ cfg ];
        nixpkgs.pkgs = lib.mkForce pkgs;
        nixpkgs.localSystem.system = system;
        deployment.targetUser = "root";
      };
in
{
  "dallben" = mkHost dallben/configuration.nix "x86_64-linux";
  "fflewddur" = mkHost fflewddur/configuration.nix "x86_64-linux";
  "fflam" = mkHost fflam/configuration.nix "aarch64-linux";
}
