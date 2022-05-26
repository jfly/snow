{ pkgs }:

pkgs.volnoti.overrideAttrs (oldAttrs: {
  # Override src to use this fork: https://github.com/hcchu/volnoti
  # rather than this fork: https://github.com/davidbrazdil/volnoti.
  # The original repo doesn't have the features needed for
  # volnoti-brightness, see
  # https://github.com/hcchu/volnoti#new-options-in-this-fork for
  # details.
  src = pkgs.fetchFromGitHub {
    owner = "hcchu";
    repo = "volnoti";
    rev = "c5a94af7338d86ba015f11a2d0ce288ba5f5cbb6";
    sha256 = "X0SFueZBx96bY2uJce2DXGFtkQhW6HDF39JD15hQCJI=";
  };

  # No patches needed on this fork.
  patches = [ ];
})
