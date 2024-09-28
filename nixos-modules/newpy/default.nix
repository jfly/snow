{ lib, pkgs, ... }:

let
  newpy = pkgs.writeShellApplication {
    name = "newpy";
    text = builtins.readFile ./newpy;
  };
in
{
  programs.bash.interactiveShellInit =
    # bash
    ''
      newpy() {
          if dir=$(${lib.getExe newpy}); then
              cd "$dir"
          else
              return $?
          fi
      }
    '';

  programs.fish.interactiveShellInit =
    # fish
    ''
      function newpy
          set -l dir (${lib.getExe newpy})
          if test $status -eq 0
              cd $dir
          else
              return $status
          end
      end
    '';
}
