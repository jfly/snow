{
  inputs,
  inputs',
  lib,
  flake,
  flake',
  pkgs,
  ...
}:

let
  inherit (builtins)
    concatStringsSep
    ;

  pulumiCrdsBuildEnv = {
    CRD_2_PULUMI_BIN = lib.getExe pkgs.crd2pulumi;
    CRDS =
      let
        crds = [
          (pkgs.fetchurl {
            url = "https://github.com/cert-manager/cert-manager/releases/download/v1.17.1/cert-manager.crds.yaml";
            hash = "sha256-E013nz0IZKd6ARP+CjTFgci1Tr2R8y109y7ifN7V1mE=";
          })
          (pkgs.fetchurl {
            url = "https://raw.githubusercontent.com/traefik/traefik/refs/tags/v3.3.2/docs/content/reference/dynamic-configuration/traefik.io_middlewares.yaml";
            hash = "sha256-c/BumomtKei3YbZP+r9oo0I7YW6Q3FkwQLz149pPi4M=";
          })
        ];
      in
      concatStringsSep " " crds;
  };

  python = pkgs.python3;

  workspace = inputs.uv2nix.lib.workspace.loadWorkspace {
    workspaceRoot = ./.;
  };

  overlay = workspace.mkPyprojectOverlay {
    sourcePreference = "wheel";
  };

  pyprojectOverrides = final: prev: {
    pulumi-crds = prev.pulumi-crds.overrideAttrs (oldAttrs: {
      env = pulumiCrdsBuildEnv;

      # We need a `$HOME` for `py-generator-build-backend`:
      # <https://github.com/jfly/py-generator-build-backend?tab=readme-ov-file#notes>
      preBuild = ''
        export HOME=$(mktemp -d)
      '';
    });
  };

  pythonSet =
    (pkgs.callPackage inputs.pyproject-nix.build.packages {
      inherit python;
    }).overrideScope
      (
        lib.composeManyExtensions [
          inputs.pyproject-build-systems.overlays.default
          overlay
          pyprojectOverrides
        ]
      );

  secret = encrypted: {
    type = "secret";
    path = flake.lib.deage.repoPath encrypted;
  };
  plaintext = str: {
    type = "plaintext";
    inherit str;
  };
  expression = expr: {
    type = "expression";
    expression = expr;
  };
  shellEnvValues = {
    # We use <https://github.com/jfly/flake-input-patcher>, which relies on IFD.
    NIX_CONFIG = plaintext ''
      allow-import-from-derivation = true
    '';

    # Workaround for <https://git.clan.lol/clan/clan-core/issues/4624>
    # Note: this environment variable doesn't exist upstream, it's only present
    # because of a patch I've added to clan.
    CLAN_BUILD_HOST = plaintext "localhost";

    SOPS_AGE_KEY_FILE = plaintext "/home/jeremy/sync/jfly-linux-secrets/age/key.txt";

    PULUMI_CONFIG_PASSPHRASE = secret ''
      -----BEGIN AGE ENCRYPTED FILE-----
      YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSB6RU0wSVR1cWJMUFRkSUxG
      enRmWnpZL2V5c2JFb3FaOTFqTGRlbVVYMUE4CnQzdmlpa2U3QjJxQ2RtQUpRMVBh
      WWk0YjZPYlNMYW85b1VNOHdlMVAzVEUKLS0tIGJCaThVR3RvT0pVRnNCR21NbmpP
      RVJnMjg3b3VGL2NxWG1ZN2syaUdBNGMKS7ChE4gYpW90dInSGzPYBZOZsLMi0l+o
      U/ZyGUi0NXR+3mzKtN9j/mgPmrGzmfvhkGFVWA==
      -----END AGE ENCRYPTED FILE-----
    '';

    # https://dash.cloudflare.com/profile/api-tokens
    CLOUDFLARE_API_TOKEN = secret ''
      -----BEGIN AGE ENCRYPTED FILE-----
      YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSAzZ3N2WHlBclZHWFI4L1NR
      K2MzQzJMbnVtdEFhei9VNEpTSWtwSDFjVFg4Cmt2WWd2b0tKaVNHUmFwWHJ0SzRE
      bENHS2dra3pGZUMvS045OXhvTzJmbWcKLS0tIDdLNlF2UjdzZERLVS93ck02RHB0
      dXozSTh5d2s2UStWUjg0cHJlUWRxYVEKX/TReXYpi1At4fYpLvCmEgnE2GUgiqBF
      mXity+YrzMYSevmN58otx7C8qiHtMbIhrX+fpgPseku5BvHUad2XloHk5m1d/26K
      -----END AGE ENCRYPTED FILE-----
    '';

    KUBECONFIG = expression "$PWD/iac/k8s/kube/config.secret";
  };

  setEnvVars = lib.mapAttrsToList (
    name: envValue:
    {
      secret = ''
        if [ -e ${envValue.path} ]; then
          export ${name}=$(<${envValue.path})
        else
          echo "Could not find decrypted ${name}. Try running 'python -m tools.deage && direnv reload'"
        fi
      '';
      plaintext = "export ${name}=${lib.escapeShellArg envValue.str}";
      expression = "export ${name}=${envValue.expression}";
    }
    .${envValue.type}
  ) shellEnvValues;
in

pkgs.mkShell {
  nativeBuildInputs = [
    inputs'.clan-core.packages.default
    pkgs.uv
    pkgs.age

    # k8s stuff
    pkgs.kubectl
    (pkgs.pulumi.withPackages (pulumiPackages: with pulumiPackages; [ pulumi-python ]))
    (pythonSet.mkVirtualEnv "devshell" workspace.deps.all)
  ];

  env = pulumiCrdsBuildEnv // {
    CLAN_NO_COMMIT = "1";
  };

  shellHook = concatStringsSep "\n" ([ flake'.config.pre-commit.installationScript ] ++ setEnvVars);
}
