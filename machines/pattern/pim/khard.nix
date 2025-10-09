{ pkgs, ... }:
let
  khardConfig = pkgs.writeTextFile {
    name = "khard.conf";
    text = # toml
      ''
        [addressbooks]
        [[all]]
        path = ~/pim/contacts/**
        type = discover
      '';
  };
  myKhard = pkgs.symlinkJoin {
    inherit (pkgs.khard) name meta;
    paths = [ pkgs.khard ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/khard --add-flags "--config ${khardConfig}"
    '';
  };
in
{
  environment.systemPackages = [
    myKhard
  ];
}
