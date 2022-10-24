{ pkgs, mach-nix }:

version: (
  mach-nix.mkPython {
    requirements = ''
      poetry == ${version}
    '';
  }
)
