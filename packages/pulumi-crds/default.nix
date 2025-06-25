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
      url = "https://github.com/cert-manager/cert-manager/releases/download/v1.17.1/cert-manager.crds.yaml";
      hash = "sha256-E013nz0IZKd6ARP+CjTFgci1Tr2R8y109y7ifN7V1mE=";
    })
    (fetchurl {
      url = "https://raw.githubusercontent.com/traefik/traefik/refs/tags/v3.3.2/docs/content/reference/dynamic-configuration/traefik.io_middlewares.yaml";
      hash = "sha256-c/BumomtKei3YbZP+r9oo0I7YW6Q3FkwQLz149pPi4M=";
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
    (pulumi.overrideAttrs (oldAttrs: {
      # See comment below about `skipFlakeCheckBuild` for the weird state that
      # `pulumi-kubernetes` is in. Hopefully this will all just go away at
      # some point.
      meta = oldAttrs.meta // {
        broken = false;
      };
    }))
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
