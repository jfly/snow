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
  };
in
version: versions.${version}
