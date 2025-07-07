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
    # We use IFD in `flake.nix` to patch flake inputs.
    NIX_CONFIG = plaintext ''
      allow-import-from-derivation = true
    '';

    SOPS_AGE_KEY_FILE = plaintext "/home/jeremy/sync/jfly-linux-secrets/age/key.txt";

    # Credentials to talk to `minio` (a self-hosted file server that
    # implements the S3 API).
    AWS_ACCESS_KEY_ID = secret ''
      -----BEGIN AGE ENCRYPTED FILE-----
      YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSByc0RjL1VESElmbnVDQ0Jk
      VVBITXgrSlk0MTFuTlVQTGtqeXUyMytIblVjClZIb1ZDbHlBZjJDcnQyQW9GZzNW
      NENERWJUOU4wZTJ1eFFkNE14WmFBcWcKLS0tIHYxNFBCUFlnc3BaY1d2eldMR2hz
      TmZicEdlVUVpYm9odzZSUkN0ZGJnRlkKAPIKfC6SSsQNQLqWWqVN+MucUVN1l1D6
      g/S7HsJm5j46iTYN
      -----END AGE ENCRYPTED FILE-----
    '';

    AWS_SECRET_ACCESS_KEY = secret ''
      -----BEGIN AGE ENCRYPTED FILE-----
      YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSB2SGtaRlN5Q0IrQXFnQXR2
      MytRSXFkcGd6MXh3M05xdldEY3Z0WTNNZGdjCjltUWc2S3RMWWRId0g0eUVUUHhz
      Umk2empWSXF3dTVMcmgyeE5pbVc2dWsKLS0tIFpwNFFnN1FHbFBJVHpDckk1S1d0
      Sm00MWpvbVJlWk4vVkIrb09MQmxhQkkKeeZwFEYdQFVyok+F/FEpGjK2I6hXOTxy
      yeQL3c9LBDac5ZjwmxWse7JyLStg0Sk3XrG0rQ==
      -----END AGE ENCRYPTED FILE-----
    '';
    # This region doesn't mean anything to `minio`, but some AWS SDKs expect you
    # to have a region set.
    AWS_REGION = plaintext "us-west-2";

    PULUMI_CONFIG_PASSPHRASE = secret ''
      -----BEGIN AGE ENCRYPTED FILE-----
      YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSB6RU0wSVR1cWJMUFRkSUxG
      enRmWnpZL2V5c2JFb3FaOTFqTGRlbVVYMUE4CnQzdmlpa2U3QjJxQ2RtQUpRMVBh
      WWk0YjZPYlNMYW85b1VNOHdlMVAzVEUKLS0tIGJCaThVR3RvT0pVRnNCR21NbmpP
      RVJnMjg3b3VGL2NxWG1ZN2syaUdBNGMKS7ChE4gYpW90dInSGzPYBZOZsLMi0l+o
      U/ZyGUi0NXR+3mzKtN9j/mgPmrGzmfvhkGFVWA==
      -----END AGE ENCRYPTED FILE-----
    '';

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

    # For building/pushing docker images
    pkgs.skopeo

    # Used by `tools/gen_mosquitto_user.py`
    pkgs.mosquitto

    # Used by `tools/gen_wg_peer.py`
    pkgs.wireguard-tools

    # k8s stuff
    pkgs.kubectl
    (pkgs.pulumi.withPackages (pulumiPackages: with pulumiPackages; [ pulumi-python ]))
    (pythonSet.mkVirtualEnv "devshell" workspace.deps.all)
  ];

  env = pulumiCrdsBuildEnv;

  shellHook = concatStringsSep "\n" ([ flake'.config.pre-commit.installationScript ] ++ setEnvVars);
}
