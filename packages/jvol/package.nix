{ pkgs }:

let
  jvol =
    with pkgs.python3Packages;
    buildPythonApplication {
      pname = "jvol";
      version = "1.0";
      format = "pyproject";

      nativeBuildInputs = [ setuptools ];
      src = ./.;
    };
in
pkgs.symlinkJoin {
  name = "jvol";
  paths = [ jvol ];
  buildInputs = [ pkgs.makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/jvol \
      --prefix PATH : ${
        pkgs.lib.makeBinPath [
          pkgs.pamixer
          pkgs.libnotify
        ]
      }
  '';
}
