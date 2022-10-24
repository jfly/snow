{ pkgs ? import <nixpkgs> { } }:

let
  base16-alacritty = pkgs.fetchFromGitHub {
    owner = "aarowill";
    repo = "base16-alacritty";
    rev = "914727e48ebf3eab1574e23ca0db0ecd0e5fe9d0";
    sha256 = "sha256-oDsuiKx8gt+Ov7hZ9PibIQtE81IRSLO+n5N99WeiK34=";
  };
in
pkgs.writeShellApplication {
  name = "colorscheme";
  runtimeInputs = [ ];
  text = ''
    export COLORSCHEME_PATH=${./colorschemes}:${base16-alacritty}
    ${builtins.readFile ./colorscheme}
  '';
}
