{ config, lib, pkgs, ... }:

{
  programs.zsh.interactiveShellInit = ''
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
          ${pkgs.sox}/bin/play -q ${./wav}/ootinee.wav &|
      else
          ${pkgs.sox}/bin/play -q ${./wav}/doh.wav &|
      fi

      # Preserve the exit code.
      return $success
    }
  '';
}
