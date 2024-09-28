{ flake', ... }:

{

  environment.systemPackages = with flake'.packages; [
    jgit
  ];

  programs.bash.interactiveShellInit =
    # bash
    ''
      co() {
          if dir=$(jgit co "$@"); then
              cd "$dir"
          else
              return $?
          fi
      }
    '';

  programs.fish.interactiveShellInit =
    # fish
    ''
      function co
          set -l dir (jgit co $argv)
          if test $status -eq 0
              cd $dir
          else
              return $status
          end
      end
    '';
}
