{ pkgs }:
let
  versions = {
    "3.8.10" = pkgs.python38.override {
      sourceVersion = {
        major = "3";
        minor = "8";
        patch = "10";
        suffix = "";
      };
      sha256 = "sha256-avJKZgk92EC8zPNx1ARKMCfmVc8kWRzibkgCK8eSGdk=";
    };
    "2.7.17" = (pkgs.python27.override {
      sourceVersion = {
        major = "2";
        minor = "7";
        patch = "17";
        suffix = "";
      };
      sha256 = "sha256-TUPwM829Cqe3AjyBsOmG/RHmU7UkjayRRNUI8RgSukE=";
      packageOverrides = pkgs.callPackage ./py2-virtualenv-packages.nix { };
    }).withPackages (ps: with ps; [ pip virtualenv ]);
  };
in
version: versions.${version}
