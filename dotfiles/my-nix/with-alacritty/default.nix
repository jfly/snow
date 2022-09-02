{ pkgs ? ((import ../sources.nix).nixpkgs { })
, unpywrap ? (pkgs.callPackage ../unpywrap.nix { })
, alacritty ? pkgs.alacritty
,
}:

let
  with-alacritty = pkgs.symlinkJoin {
    name = "with-alacritty";
    paths = [ (unpywrap (pkgs.callPackage ./derivation.nix { })) ];
    buildInputs = [ pkgs.makeWrapper ];
    # Set up a pointer to the real alacritty so we don't end up with an
    # infinite loop because of the alacritty-direct wrapper we're creating
    # below.
    postBuild = ''
      for f in $out/bin/*; do
          wrapProgram $f --set WITH_ALACRITTY_RAW_ALACRITTY_BIN ${alacritty}/bin/alacritty
      done
    '';
  };
  # This was inspired by https://github.com/alacritty/alacritty/issues/472
  #  > You could work around this by spawning a new config for each Alacritty
  #  > instance. Copying from the default location. That would certainly work
  #  > and isn't too much work, though it is a bit hacky.
  # TODO: replace this with new IPC mechanism: https://github.com/alacritty/alacritty/commit/4ddb608563d985060d69594d1004550a680ae3bd
  alacritty-direct = pkgs.writeShellScriptBin "alacritty" ''
    # Don't let alacritty guess the DPI of the screen: it only affects new
    # terminals. Instead, let our `autoperipherals` script handle everything.
    # See https://github.com/alacritty/alacritty/issues/5449 for details.
    export WINIT_X11_SCALE_FACTOR=1.0
    exec ${with-alacritty}/bin/with-alacritty alacritty "$@"
  '';
in
pkgs.symlinkJoin {
  name = "alacritty";
  paths = [
    with-alacritty
    alacritty-direct
  ];
}
