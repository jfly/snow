{ outputs, pkgs, flakeRoot }:
let
  mkApp = drv: {
    type = "app";
    program = "${drv}";
  };
in
{
  "agenix-rooter-generate" = mkApp (import ./agenix-rooter-generate.nix { inherit outputs pkgs flakeRoot; });
}
