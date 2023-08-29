{ lib
, python3
, ps
, writeShellScript
, callPackage
, unpywrap ? (callPackage ../unpywrap.nix { })
,
}:

let
  pipwrap = writeShellScript "pipwrapper" ''
    exec python -m pip "$@"
  '';
  shtuff = with python3.pkgs; buildPythonApplication rec {
    pname = "shtuff";
    version = "0.3.2";

    src = fetchPypi {
      inherit pname version;
      sha256 = "sha256-hp4Ue3WzvOol/+ZU9vYhpMUY68TTl8ZMVbtcH8JjcGM=";
    };

    propagatedBuildInputs = [
      pexpect
      psutil
      pyxdg
      setproctitle
      setuptools
      setuptools_scm
    ];

    nativeCheckInputs = [
      pip
    ];

    checkPhase = ''
      # venv uses ensurepip internally to install pip, which requires
      # internet access, and fails in an isolated build environment.
      # Instead, we hack together a pip that simply calls `python -m
      # pip`. There must be a better way of doing this...
      python -m venv venv --without-pip
      cp ${pipwrap} venv/bin/pip
      source venv/bin/activate

      make test
    '';

    postPatch = ''
      # shtuff uses `ps` internally. Point that to a direct path to ps.
      substituteInPlace shtuff.py \
        --replace "ps -p" "${ps}/bin/ps -p"
    '';

    meta = with lib; {
      inherit version;
      description = "It's like screen's stuff command, without screen";
      longDescription = ''
        Shell stuff will stuff commands into a shell à la tmux send-keys or screen stuff.
      '';
      homepage = "https://github.com/jfly/shtuff";
      license = licenses.mit;
    };
  };
in

unpywrap shtuff
