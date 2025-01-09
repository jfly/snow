{
  inputs,
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

  poetry2nix = inputs.poetry2nix.lib.mkPoetry2Nix { inherit pkgs; };
  unwrap =
    app:
    pkgs.symlinkJoin {
      name = app.name;
      paths = [ app ];
      buildInputs = [ ];
      postBuild = ''
        for full_path in ${app}/bin/.*-wrapped; do
          f=$(basename $full_path)
          f=''${f#.}  # remove leading dot
          f=''${f%-wrapped}  # remove trailing -wrapped

          rm $out/bin/$f
          cp ${app}/bin/.$f-wrapped $out/bin/$f
          chmod +x $out/bin/$f
        done
      '';
    };

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
    # We use IFD in `flake-modules/patched-nixpkgs.nix`.
    NIX_CONFIG = plaintext ''
      allow-import-from-derivation = true
    '';

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
    pkgs.age

    # For building/pushing docker images
    pkgs.skopeo

    # Used by `tools/gen_mosquitto_user.py`
    pkgs.mosquitto

    # Used by `tools/gen_wg_peer.py`
    pkgs.wireguard-tools

    # k8s stuff
    pkgs.kubectl
    # pulumi-bin wraps pulumi with a shell script that sets LD_LIBRARY_PATH,
    # which causes issues when pulumi tries to invoke subprocesses.
    # For example:
    #  ```
    #  $ LD_LIBRARY_PATH=/nix/store/bym6162f9mf4qqsr7k9d73526ar176x4-gcc-11.3.0-lib/lib python --version
    #  /nix/store/x24kxyqwqg2ln8kh9ky342kdcmhbng3h-python3-3.9.9/bin/python: /nix/store/jcb7fny2k03pfbdqk1hcnh12bxgax6vf-glibc-2.33-108/lib/libc.so.6: version `GLIBC_2.34' not found (required by /nix/store/bym6162f9mf4qqsr7k9d73526ar176x4-gcc-11.3.0-lib/lib/libgcc_s.so.1)
    #  ```
    #
    # This environment variable was added a while ago in
    # https://github.com/NixOS/nixpkgs/pull/81879, but things seem to work now
    # without it. :shrug:
    # TODO: file an issue upstream with nixpkgs?
    (unwrap pkgs.pulumi-bin)
    pkgs.poetry
    (poetry2nix.mkPoetryEnv {
      projectDir = ./.;
      extraPackages = ps: [
        ps.pip # Used by `pulumi about` and `pulumi up`.
        (flake'.packages.pulumi-crds.override { python3 = ps.python; })
      ];
      overrides = poetry2nix.defaultPoetryOverrides.extend (
        final: prev: {
          click = prev.click.overridePythonAttrs (old: {
            buildInputs = (old.buildInputs or [ ]) ++ [ prev.flit-core ];
          });
          remote-pdb = prev.remote-pdb.overridePythonAttrs (old: {
            buildInputs = (old.buildInputs or [ ]) ++ [ prev.setuptools ];
          });
          paho-mqtt = prev.paho-mqtt.overridePythonAttrs (old: {
            buildInputs = (old.buildInputs or [ ]) ++ [ prev.hatchling ];
          });
          pulumi-keycloak = prev.pulumi-keycloak.overridePythonAttrs (old: {
            buildInputs = (old.buildInputs or [ ]) ++ [ prev.setuptools ];
          });
          pulumi-cloudflare = prev.pulumi-cloudflare.overridePythonAttrs (old: {
            buildInputs = (old.buildInputs or [ ]) ++ [ prev.setuptools ];
          });
          pulumi-minio = prev.pulumi-minio.overridePythonAttrs (old: {
            buildInputs = (old.buildInputs or [ ]) ++ [ prev.setuptools ];
          });
          pyyaml = prev.pyyaml.overridePythonAttrs (old: {
            # https://github.com/yaml/pyyaml/pull/823
            # fix: don't import deprecated "wheel" (just to do nothing with it)
            # This fixes (works around?) https://github.com/pypa/setuptools/issues/4683
            patches = (if old ? patches then old.patches else [ ]) ++ [
              (pkgs.fetchpatch {
                url = "https://patch-diff.githubusercontent.com/raw/yaml/pyyaml/pull/823.patch";
                hash = "sha256-FA8J6X9HcwrsirAY+pjQJLdwzK9imwVNY+e35XGa9pc=";
              })
            ];
          });
          wgconfig = prev.wgconfig.overridePythonAttrs (old: {
            buildInputs = (old.buildInputs or [ ]) ++ [ prev.setuptools ];
          });
        }
      );
    })
  ];

  shellHook = concatStringsSep "\n" ([ flake'.config.pre-commit.installationScript ] ++ setEnvVars);
}
