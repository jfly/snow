{ pkgs ? import <nixpkgs> { } }:

with pkgs.python3Packages; buildPythonApplication {
  pname = "polybar-openvpn3";
  version = "1.0";
  format = "pyproject";

  nativeBuildInputs = [ setuptools ];
  src = ./.;

  propagatedBuildInputs = pkgs.openvpn3.pythonPath ++ [
    (pkgs.openvpn3.overrideAttrs (oldAttrs: {
      patches = [
        # TODO: remove this if/when
        # https://sourceforge.net/p/openvpn/mailman/message/37868192/ is
        # accepted and makes its way to nixpkgs-unstable.
        (pkgs.fetchpatch {
          url = "https://github.com/jfly/openvpn3-linux/commit/e0a8a3c5c2ef10509f4bee844714d6b072f3b690.patch";
          sha256 = "sha256-YCtJyXcjOG1jCUQk1jtC9JqCSfSie2tMyEu+CFZ9ZRg=";
        })
        (pkgs.fetchpatch {
          url = "https://github.com/jfly/openvpn3-linux/commit/3663bd4cbaa7a82608bd1b65b4e24ca822e7412d.patch";
          sha256 = "sha256-DQv7I/zQlN+bLUg/m4spPG132k74FSA0KFSGVD6OXdE=";
        })
      ];
    }))
  ];
}
