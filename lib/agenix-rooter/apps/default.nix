{
  flake,
  pkgs,
  flakeRoot,
  ...
}:
let
  mkApp = drv: {
    type = "app";
    program = "${drv}";
  };
in
{
  "agenix-rooter-generate" = mkApp (
    import ./agenix-rooter-generate.nix { inherit flake pkgs flakeRoot; }
  );
}
