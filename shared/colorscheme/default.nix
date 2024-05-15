{ pkgs ? import <nixpkgs> { } }:

let
  base16-alacritty = pkgs.fetchFromGitHub {
    owner = "aarowill";
    repo = "base16-alacritty";
    rev = "c95c200b3af739708455a03b5d185d3d2d263c6e";
    sha256 = "sha256-TNxKbwdiUXGi4Z4chT72l3mt3GSvOcz6NZsUH8bQU/k=";
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
