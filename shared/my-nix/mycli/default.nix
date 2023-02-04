{ pkgs ? import <nixpkgs> { } }:

pkgs.symlinkJoin {
  name = "mycli";

  # Tests are disabled as a workaround for https://github.com/NixOS/nixpkgs/issues/211415.
  # paths = [ pkgs.mycli ];
  paths = [
    (pkgs.mycli.overridePythonAttrs (oldAttrs: {
      doCheck = false;
    }))
  ];

  buildInputs = [ pkgs.makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/mycli \
      --add-flags "--myclirc ${./myclirc}"
  '';
}
