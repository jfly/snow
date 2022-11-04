{ pkgs }:
let
  mkPy27 = { sourceVersion, sha256 }: (
    let
      py27NoVenv = (pkgs.python27.override {
        self = py27NoVenv;
        inherit sourceVersion sha256;
        packageOverrides = pkgs.callPackage ./py2-virtualenv-packages.nix { };
      });
    in
    py27NoVenv.withPackages (ps: with ps; [ pip virtualenv ])
  );

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
    "3.6.9" = pkgs.python37.override {
      sourceVersion = {
        major = "3";
        minor = "6";
        patch = "9";
        suffix = "";
      };
      sha256 = "sha256-Xi9fVU4/j38ClvfnPYYAxOmsuu5rJVW4Mgbt9RU4cNo=";
    };
    "2.7.17" = mkPy27 {
      sourceVersion = {
        major = "2";
        minor = "7";
        patch = "17";
        suffix = "";
      };
      sha256 = "sha256-TUPwM829Cqe3AjyBsOmG/RHmU7UkjayRRNUI8RgSukE=";
    };
    "2.7.18" = mkPy27 {
      sourceVersion = {
        major = "2";
        minor = "7";
        patch = "18";
        suffix = "";
      };
      sha256 = "sha256-tiwOeTdVHQzAK4/Vyw9UT5QFuvyaVNOAjtRZSBLt70M=";
    };
  };
in
version: versions.${version}