{ lib, pkgs, ... }:

let
  nix-hack = pkgs.writeShellApplication {
    name = "nix-hack";
    text = builtins.readFile ./nix-hack;
  };
in
{
  programs.bash.interactiveShellInit =
    # bash
    ''
      nix-hack() {
          if dir=$(${lib.getExe nix-hack}); then
              cd "$dir"
          else
              return $?
          fi
      }
    '';

  programs.fish.interactiveShellInit =
    # fish
    ''
      function nix-hack
          set -l dir (${lib.getExe nix-hack})
          if test $status -eq 0
              cd $dir
          else
              return $status
          end
      end
    '';
}
