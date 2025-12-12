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

  python = pkgs.python3;

  workspace = inputs.uv2nix.lib.workspace.loadWorkspace {
    workspaceRoot = ./.;
  };

  overlay = workspace.mkPyprojectOverlay {
    sourcePreference = "wheel";
  };

  pythonSet =
    (pkgs.callPackage inputs.pyproject-nix.build.packages {
      inherit python;
    }).overrideScope
      (
        lib.composeManyExtensions [
          inputs.pyproject-build-systems.overlays.default
          overlay
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
    }
    .${envValue.type}
  ) shellEnvValues;
in

pkgs.mkShell {
  nativeBuildInputs = [
    inputs'.clan-core.packages.default
    pkgs.uv
    pkgs.age

    # Pulumi stuff
    (pkgs.pulumi.withPackages (pulumiPackages: with pulumiPackages; [ pulumi-python ]))
    (pythonSet.mkVirtualEnv "devshell" workspace.deps.all)
  ];

  env = {
    CLAN_NO_COMMIT = "1";
  };

  shellHook = concatStringsSep "\n" ([ flake'.config.pre-commit.installationScript ] ++ setEnvVars);
}
