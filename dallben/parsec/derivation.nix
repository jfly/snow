{ pkgs, parsec-gaming }:

let
  parsec = pkgs.callPackage parsec-gaming { };
  stopParsec = (pkgs.writeShellScriptBin "stop_parsec.sh" "sudo pkill parsecd");
  startParsec = pkgs.writeShellScriptBin "parsecd" ''
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
  myParsec = pkgs.symlinkJoin {
    name = "parsec";
    paths = [ startParsec stopParsec ];
  };
in
myParsec
