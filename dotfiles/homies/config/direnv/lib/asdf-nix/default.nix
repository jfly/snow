{ pkgs ? import <nixpkgs> { }, mach-nix }:

let
  lib = pkgs.lib;

  asdfPlugins = {
    python = pkgs.callPackage ./python.nix { };
    java = pkgs.callPackage ./java.nix { };
    maven = pkgs.callPackage ./maven.nix { };
    thrift = pkgs.callPackage ./thrift { };
    poetry = pkgs.callPackage ./poetry.nix { inherit mach-nix; };
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
  asdfLines = (tool-versions:
    let lines = lib.splitString "\n" tool-versions;
    in builtins.filter (line: lib.stringLength line > 0 && builtins.head (lib.stringToCharacters line) != "#") lines
  );
  fakeAsdf = pkgs.writeShellScriptBin "asdf" ''
    echo "This is a bogus asdf to shadow the real asdf because you're using asdf-nix"
  '';
  asdf = {
    pkgs = { tool-versions }: [ fakeAsdf ] ++ (builtins.map asdfLineToPkg (asdfLines tool-versions));
  };
in
asdf
