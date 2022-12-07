{ config, pkgs, parsec-gaming, lib, ... }:

let
  parsec = pkgs.callPackage parsec-gaming { };
  my_parsec = pkgs.writeShellScriptBin "parsecd" ''
    # This script wraps the real parsecd so it can exit 0 if stopped by stop_parsec.sh.

    CAUGHT_TERM=""
    _term() {
      CAUGHT_TERM="yep"
      echo "Caught SIGTERM signal! Forwarding that onto $CHILD_PID" >/dev/stderr
      kill -TERM "$CHILD_PID" 2>/dev/null
    }
    trap _term SIGTERM

    ${parsec}/bin/parsecd "$@" &
    CHILD_PID=$!
    wait "$CHILD_PID"
    RET=$?
    if [ -n "$CAUGHT_TERM" ]; then
      echo "Caught SIGTERM signal! Treating that as a graceful shutdown." >/dev/stderr
      exit 0
    fi
    echo "Parsec exited on its own. Bubbling up its exit code." >/dev/stderr
    exit "$RET"
  '';
in
{
  environment.systemPackages = [
    my_parsec
    (pkgs.writeShellScriptBin "stop_parsec.sh" "sudo pkill parsecd")
  ];

  # Give gurgi ssh access so it can run stop_parsec.sh
  # TODO: lock down permissions so that's the *only* thing it can do.
  users.users.gurgi = {
    isNormalUser = true;
    extraGroups = [
      "wheel" # Enable `sudo` for the user.
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPog+FoId+C37SnL1VfwRE11pGzzvxOM0GL0HjOL1Qqf gurgi@snowdon"
    ];
  };
}
