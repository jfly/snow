{ pkgs ? import <nixpkgs> { } }:

let
  lib = pkgs.lib;

  asdfPlugins = {
    python = pkgs.callPackage ./python.nix { };
    java = pkgs.callPackage ./java.nix { };
    maven = pkgs.callPackage ./maven.nix { };
    thrift = pkgs.callPackage ./thrift { };
    poetry = pkgs.callPackage ./poetry.nix { };
    nodejs = pkgs.callPackage ./nodejs.nix { };
    yarn = pkgs.callPackage ./yarn.nix { };
  };

  asdfToPkg = { plugin, version }: (asdfPlugins.${plugin} version);
  parseAsdfLine = (asdfLine:
    let pluginAndVersion = lib.splitString " " asdfLine;
    in {
      # Urg, is this really the best way to unpack a list in nix?
      plugin = builtins.head pluginAndVersion;
      version = builtins.head (builtins.tail pluginAndVersion);
    }
  );
  asdfLineToPkg = (asdfLine: asdfToPkg (parseAsdfLine asdfLine));
  asdfLines = (file:
    let lines = lib.splitString "\n" (builtins.readFile file);
    in builtins.filter (line: lib.stringLength line > 0 && builtins.head (lib.stringToCharacters line) != "#") lines
  );
  asdf = {
    pkgs = file: builtins.map asdfLineToPkg (asdfLines file);
    shell = file: (
      pkgs.mkShell {
        nativeBuildInputs = asdf.pkgs file;
      }
    );
  };
in
asdf
