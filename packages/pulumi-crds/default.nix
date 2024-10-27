{
  crd2pulumi,
  runCommand,
  lib,
  buildPythonPackage,
  fetchurl,
  parver,
  pulumi,
  requests,
  semver,
  setuptools,
  typing-extensions,
  # This is a hack: this package truly does depend on pulumi-kubernetes, but
  # pulumi-kubernetes is not in `nixpkgs`. That works fine for our `devShell`,
  # because it pulls in pulumi-kubernetes via poetry2nix (and overrides the
  # python package set used here).
  # This is fine, we're not packaging this for other people to use. However, we
  # do need this code to evaluate properly so we don't break `nix flake check`.
  pulumi-kubernetes ? null,
}:

let
  inherit (lib)
    getExe
    ;
  inherit (builtins)
    concatStringsSep
    ;
  crds = [
    (fetchurl {
      url = "https://github.com/cert-manager/cert-manager/releases/download/v1.13.2/cert-manager.crds.yaml";
      sha256 = "sha256-b2U1SZVPZ2JexaPqub8csRtBUi7bBo2zPlrkJQWYCBk=";
    })
    (fetchurl {
      url = "https://raw.githubusercontent.com/jfly/traefik/2.9.10-custom-status-code-for-ip-list-middleware/docs/content/reference/dynamic-configuration/traefik.containo.us_middlewares.yaml";
      sha256 = "sha256-ZqN9xu5zSBsmuau/feJjT+0vlUudp1vsMceUJl/fJYI=";
    })
  ];

  name = "crds";
  version = "1.0.0";
  src = runCommand "pulumi-crds-src" { } ''
    ${getExe crd2pulumi} --pythonPath $out --pythonName ${name} --version ${version} ${concatStringsSep " " crds}
  '';
in

buildPythonPackage {
  pname = "pulumi-${name}";
  inherit version src;

  pyproject = true;
  build-system = [ setuptools ];
  pythonImportsCheck = [ "pulumi_crds" ];

  propagatedBuildInputs = [
    parver
    pulumi
    pulumi-kubernetes
    requests
    semver
    typing-extensions
  ];

  # This package depends on `python3.pkgs.pulumi`, which doesn't currently build:
  # https://github.com/NixOS/nixpkgs/issues/351751
  # However (for some reason I don't understand) this *does* build when used
  # via our `devShell` (which does override the Python package set, so perhaps
  # that's relevant).
  # The presence of `pulumi-kubernetes` is a hack (see parameter documentation
  # above) to detect if we're being used inside that `devShell`.
  passthru.skipFlakeCheckBuild = pulumi-kubernetes == null;
}
