{ pkgs }:

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
  mfa-askpass = pkgs.writeShellApplication {
    name = "mfa-askpass";
    runtimeInputs = [ twofa-cli ];
    text = builtins.readFile ./src/mfa-askpass;
  };
in
pkgs.symlinkJoin {
  name = "mfa";
  paths = [ twofa twofa-cli mfa-askpass ];
}
