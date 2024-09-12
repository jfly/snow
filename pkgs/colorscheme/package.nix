{ fetchFromGitHub, writeShellApplication, symlinkJoin, makeWrapper, yq-go, jq, lib }:

let
  base16-alacritty = fetchFromGitHub {
    owner = "aarowill";
    repo = "base16-alacritty";
    rev = "c95c200b3af739708455a03b5d185d3d2d263c6e";
    sha256 = "sha256-TNxKbwdiUXGi4Z4chT72l3mt3GSvOcz6NZsUH8bQU/k=";
  };
in
symlinkJoin {
  name = "colorscheme";
  paths = [
    (
      writeShellApplication {
        name = "colorscheme";
        runtimeInputs = [ ];
        text = builtins.readFile ./colorscheme;
      }
    )
  ];

  buildInputs = [ makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/colorscheme \
      --set COLORSCHEME_PATH ${./colorschemes}:${base16-alacritty} \
      --prefix PATH : ${lib.makeBinPath [
        yq-go
        jq
      ]}
  '';
}
