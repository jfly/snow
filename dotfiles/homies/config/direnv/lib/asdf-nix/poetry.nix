{ pkgs }:

let
  mach-nix = import
    (builtins.fetchGit {
      url = "https://github.com/DavHau/mach-nix/";
      ref = "refs/tags/3.5.0";
    })
    {
      pypiDataRev = "d46d56e1e0e58310ec7c10604b1dfcdbd707bfd6";
      pypiDataSha256 = "sha256:1p8r0991z03ni7zr7kmjw2979izm5bx1adfmi7rqkiz6gn4xljd8";
    };
in
version: (
  mach-nix.mkPython {
    requirements = ''
      poetry == ${version}
    '';
  }
)
