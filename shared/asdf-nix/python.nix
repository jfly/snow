{ pkgs }:
let
  mkPy27 = { sourceVersion, hash }: (
    let
      py27NoVenv = (pkgs.python27.override {
        self = py27NoVenv;
        inherit sourceVersion hash;
        packageOverrides = pkgs.callPackage ./py2-virtualenv-packages.nix { };
      });
    in
    py27NoVenv.withPackages (ps: with ps; [ pip virtualenv ])
  );

  # Generated from
  # https://lazamar.co.uk/nix-versions/?package=python3&version=3.6.14&fullName=python3-3.6.14&keyName=python36&revision=407f8825b321617a38b86a4d9be11fd76d513da2&channel=nixpkgs-unstable#instructions
  oldNixpkgs = import
    (builtins.fetchGit {
      name = "nixpkgs-with-old-py3";
      url = "https://github.com/NixOS/nixpkgs/";
      ref = "refs/heads/nixpkgs-unstable";
      rev = "407f8825b321617a38b86a4d9be11fd76d513da2";
    })
    {
      localSystem = pkgs.system;
    };

  versions = {
    "3.11.9" = pkgs.python311.override {
      sourceVersion = {
        major = "3";
        minor = "11";
        patch = "9";
        suffix = "";
      };
      hash = "sha256-mx6JZSP8UQaREmyGRAbZNgo9Hphqy9pZzaV7Wr2kW4c=";
    };
    "3.11.8" = pkgs.python311.override {
      sourceVersion = {
        major = "3";
        minor = "11";
        patch = "8";
        suffix = "";
      };
      hash = "sha256-ngYAjIkBkkOVvB2jA+rFZ6cprgErqhgqs5Jp9lA4O7M=";
    };
    "3.11.7" = pkgs.python311.override {
      sourceVersion = {
        major = "3";
        minor = "11";
        patch = "7";
        suffix = "";
      };
      hash = "sha256-GOGqfmb/OlhCPVntIoFaaVTlM0ISLEXfIMlod8Biubc=";
    };
    "3.11.4" = pkgs.python311.override {
      sourceVersion = {
        major = "3";
        minor = "11";
        patch = "4";
        suffix = "";
      };
      hash = "sha256-Lw5AnfKrV6qfxMvd+5dq9E5OVb9vYZ7ua8XCKXJkp/Y=";
    };
    "3.10.12" = pkgs.python310.override {
      sourceVersion = {
        major = "3";
        minor = "10";
        patch = "12";
        suffix = "";
      };
      hash = "sha256-r7dL8ZEw56R9EDEsj154TyTgUnmB6raOIFRs+4ZYMLg=";
    };
    "3.10.10" = pkgs.python38.override {
      sourceVersion = {
        major = "3";
        minor = "10";
        patch = "10";
        suffix = "";
      };
      hash = "sha256-BBnpCFv1G3pnIAmz9Q2/GFms3xi6cl0OwZqlyFA/DqM=";
    };
    "3.10.6" = pkgs.python38.override {
      sourceVersion = {
        major = "3";
        minor = "10";
        patch = "6";
        suffix = "";
      };
      hash = "sha256-95X/h9EdSwx8M7yIUbDChkjYpFg6ohAKmMIrQya20/M=";
    };
    "3.9.10" = pkgs.python38.override {
      sourceVersion = {
        major = "3";
        minor = "9";
        patch = "10";
        suffix = "";
      };
      hash = "sha256-Co+/tSh+vDoT6brz1U4I+gZ3j/7M9jEa74Ibs6ZYbMg=";
    };
    "3.8.10" = pkgs.python38.override {
      sourceVersion = {
        major = "3";
        minor = "8";
        patch = "10";
        suffix = "";
      };
      hash = "sha256-avJKZgk92EC8zPNx1ARKMCfmVc8kWRzibkgCK8eSGdk=";
    };
    "3.6.15" = oldNixpkgs.python36.override {
      sourceVersion = {
        major = "3";
        minor = "6";
        patch = "15";
        suffix = "";
      };
      sha256 = "sha256-bijXzdbdUT3RkOSbyjly4g/PRVCQzPLvPxoidhQTXZE=";
    };
    "3.6.9" = pkgs.python37.override {
      sourceVersion = {
        major = "3";
        minor = "6";
        patch = "9";
        suffix = "";
      };
      hash = "sha256-Xi9fVU4/j38ClvfnPYYAxOmsuu5rJVW4Mgbt9RU4cNo=";
    };
    "2.7.17" = mkPy27 {
      sourceVersion = {
        major = "2";
        minor = "7";
        patch = "17";
        suffix = "";
      };
      hash = "sha256-TUPwM829Cqe3AjyBsOmG/RHmU7UkjayRRNUI8RgSukE=";
    };
    "2.7.18" = mkPy27 {
      sourceVersion = {
        major = "2";
        minor = "7";
        patch = "18";
        suffix = "";
      };
      hash = "sha256-NtDJrVmGgKrb2okcl42+La6t/aj4S2WuuktJ8VavH2s=";
    };
  };
in
version: versions.${version}
