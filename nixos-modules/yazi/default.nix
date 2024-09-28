{ lib, pkgs, ... }:

let
  yazi = pkgs.symlinkJoin {
    name = "yazi-with-extensions";
    paths = [ pkgs.yazi ];
    buildInputs = [ pkgs.makeWrapper ];
    inherit (pkgs.yazi) meta;
    postBuild = ''
      wrapProgram $out/bin/yazi \
        --prefix PATH : ${
          pkgs.lib.makeBinPath [
            # Needed for image previews in alacritty
            # https://github.com/sxyazi/yazi#image-preview
            pkgs.ueberzugpp
          ]
        }
    '';
  };
in
{
  # https://yazi-rs.github.io/docs/quick-start/#shell-wrapper
  programs.zsh.interactiveShellInit =
    # bash
    ''
      function y() {
        tmp="$(mktemp -t "yazi-cwd.XXXXX")"
        ${lib.getExe yazi} --cwd-file="$tmp"
        if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
          cd -- "$cwd"
        fi
        rm -f -- "$tmp"
      }
    '';

  # https://yazi-rs.github.io/docs/quick-start/#shell-wrapper
  programs.fish.interactiveShellInit =
    # fish
    ''
      function y
      	set tmp (mktemp -t "yazi-cwd.XXXXXX")
      	${lib.getExe yazi} $argv --cwd-file="$tmp"
      	if set cwd (command cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
      		builtin cd -- "$cwd"
      	end
      	rm -f -- "$tmp"
      end
    '';
}
