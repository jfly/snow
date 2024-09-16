{ python3, system, }:

let
  latestPkgs = import
    (builtins.fetchTarball {
      url = "https://github.com/NixOS/nixpkgs/archive/9719c6efe962d9a5b81f0c1af4a977d9056a31b0.tar.gz";
      sha256 = "sha256:0sdkm5hsxmibnnjz4qjn8wiz93gaigd4c345ifmbhiafp6mycy1y";
    })
    { inherit system; };

  latestCrd2Pulumi = latestPkgs.crd2pulumi; #<<< https://github.com/NixOS/nixpkgs/pull/341701 >>>
in

python3.pkgs.callPackage ./default.nix { crd2pulumi = latestCrd2Pulumi; }
