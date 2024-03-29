{
  projectRootFile = "flake.nix";

  programs.nixpkgs-fmt.enable = true;

  programs.black.enable = true;
  settings.formatter.black.excludes = [ "k8s-pulumi/crds/*.py" ]; # this code is autogenerated and committed :(

  programs.clang-format.enable = true;
}
