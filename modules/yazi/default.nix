{ config, lib, pkgs, ... }:

let
  yazi = pkgs.symlinkJoin {
    name = "yazi-with-extensions";
    paths = [ pkgs.yazi ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/yazi \
        --prefix PATH : ${pkgs.lib.makeBinPath [
          # Needed for image previews in alacritty
          # https://github.com/sxyazi/yazi#image-preview
          pkgs.ueberzugpp
        ]}
    '';
  };
in
{
  # Copied from
  # https://yazi-rs.github.io/docs/usage/quick-start#changing-working-directory-when-exiting-yazi
  programs.zsh.interactiveShellInit = ''
    function ya() {
        tmp="$(mktemp -t "yazi-cwd.XXXXX")"
        ${yazi}/bin/yazi --cwd-file="$tmp"
        if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
            cd -- "$cwd"
        fi
        rm -f -- "$tmp"
    }
  '';
}

