{ pkgs, ... }:

{
  programs.zsh.interactiveShellInit =
    # bash
    ''
      q() {
        # Capture the result of the previous command just in case we need it.
        local success=$?

        # If any parameters were given, treat them like a command and capture
        # their result.
        if [ $# -gt 0 ]; then
          "$@"
          success=$?
        fi

        if [ $success -eq 0 ]; then
            ${pkgs.sox}/bin/play -q ${./wav}/owin31.wav &
        else
            ${pkgs.sox}/bin/play -q ${./wav}/doh.wav &
        fi

        # Ring the bell.
        echo -e "\a"

        # Preserve the exit code.
        return $success
      }
    '';

  programs.fish.interactiveShellInit =
    # fish
    ''
      function q
        # Capture the result of the previous command just in case we need it.
        set -l success $status

        # If any parameters were given, treat them like a command and capture
        # their result.
        if test (count $argv) -gt 0
          $argv
          set success $status
        end

        if test $success -eq 0
            ${pkgs.sox}/bin/play -q ${./wav}/owin31.wav &
        else
            ${pkgs.sox}/bin/play -q ${./wav}/doh.wav &
        end

        # Ring the bell
        echo -e "\a"

        # Preserve the exit code.
        return $success
      end
    '';
}
