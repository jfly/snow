{ pkgs }:

pkgs.script-directory.overrideAttrs (oldAttrs: {
  # There hasn't been a release of sd in a while, but `main` has moved on a bit.
  version = "1.1.0-unstable-2024_03_19";
  src = pkgs.fetchFromGitHub {
    owner = "ianthehenry";
    repo = "sd";
    rev = "8a2335f765720afe01c7eca1ffbba669a66cadca";
    hash = "sha256-pp5fq+0+BaKs2ZXio5ZIyXPUQrEhE5ziNBbyTIs5FDg=";
  };

  patches = [
    # This PR adds Fish completions: <https://github.com/ianthehenry/sd/pull/18>
    (pkgs.fetchurl {
      url = "https://patch-diff.githubusercontent.com/raw/ianthehenry/sd/pull/18.patch";
      hash = "sha256-u2Ovh2t2ev3kbxWjHe4OLdjdeIwcew4P1SsyPu7YQAU=";
    })
  ];

  installPhase =
    oldAttrs.installPhase
    + ''
      installShellCompletion sd.fish
    '';
})
