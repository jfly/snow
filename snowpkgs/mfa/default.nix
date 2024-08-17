{ pkgs, stdenv, lib }:

let
  twofa = pkgs.writeShellApplication {
    name = "2fa";
    runtimeInputs = with pkgs; [
      xdotool
    ];
    text = builtins.readFile ./src/2fa;
  };
  twofa-cli = pkgs.writeShellApplication {
    name = "2fa-cli";
    runtimeInputs = with pkgs; [
      sqlite
      oath-toolkit
      zenity
    ];
    text = builtins.readFile ./src/2fa-cli;
  };
in
pkgs.symlinkJoin {
  name = "mfa";
  paths = [ twofa twofa-cli ];
}
