{
  lib,
  flake',
  pkgs,
  ...
}:
let
  inherit (flake'.packages) colorscheme;
  inherit (pkgs)
    writeShellApplication
    openssh
    ;

  light-dark-ssh = writeShellApplication {
    name = "light-dark-ssh";
    text = ''
      # If there's no DISPLAY (perhaps we're in a TTY or are sshed to this machine),
      # just ssh, don't bother with colorschemes.
      if [ -z "''${DISPLAY+x}" ]; then
        exec ${lib.getExe openssh} "$@"
      fi

      colorscheme set current base16-cupcake
      function finish {
          colorscheme clear current
      }
      trap finish EXIT

      ${lib.getExe openssh} "$@"
    '';
  };
in
{
  environment.systemPackages = [
    colorscheme
  ];

  # Note: we intentionally expose `light-dark-ssh` as a shell alias rather than
  # a `ssh` binary in the path.
  # This is nice, as it captures human triggered ssh incantations, but not
  # stuff like a `git fetch` (which invokes ssh under the hood, and would
  # result in distracting flickering).
  programs.zsh.interactiveShellInit =
    # bash
    ''
      alias ssh=${lib.getExe light-dark-ssh}
    '';

  programs.fish.interactiveShellInit =
    # fish
    ''
      alias ssh=${lib.getExe light-dark-ssh}
    '';
}
