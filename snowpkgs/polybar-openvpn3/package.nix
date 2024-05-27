{ buildPythonApplication
, wrapGAppsNoGuiHook
, setuptools
, fetchpatch
, openvpn3
}:

buildPythonApplication {
  pname = "polybar-openvpn3";
  version = "1.0";
  format = "pyproject";

  nativeBuildInputs = [
    setuptools
    wrapGAppsNoGuiHook
  ];
  src = ./.;

  propagatedBuildInputs = openvpn3.pythonPath ++ [
    (openvpn3.overrideAttrs (oldAttrs: {
      patches = [
        # TODO: remove this when v21 of openvpn3 lands on nixpkgs-unstable.
        (fetchpatch {
          url = "https://github.com/OpenVPN/openvpn3-linux/commit/ba6fe37e7e28d1e633b56052383da3072f03c11e.patch";
          sha256 = "sha256-MBXDEfeyg0VQGp9GYcpTZyLB0h6LX1qlaqZSDhOAJgQ=";
        })
      ];
    }))
  ];
}
