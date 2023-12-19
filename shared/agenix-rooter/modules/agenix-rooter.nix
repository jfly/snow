nixpkgs:
{ lib, options, config, pkgs, ... }:

let
  inherit
    (lib)
    isPath
    literalExpression
    mdDoc
    mkIf
    mkOption
    pathExists
    readFile
    types
    ;

  rooter-lib = pkgs.callPackage ../lib.nix { };
  cfg = config.age;
in
{
  config = mkIf (cfg.secrets != { }) {
    system.activationScripts.agenixRooterDerivedSecrets = {
      # Don't run until after agenix has actually generated the secrets.
      deps = [ "agenix" ];
      text = (
        ''
          rm -f /run/agenix-derived-secrets/desired-files
        ''
      ) + (
        lib.concatStringsSep "\n"
          (lib.mapAttrsToList
            (filename: generator:
              ''
                # First, create a symlink to the (not-yet-existent) derived file.
                mkdir -p /run/agenix-derived-secrets
                hash=$(echo -n '${filename}' | md5sum | cut -f1 -d " ")
                ln -sf '${filename}' "/run/agenix-derived-secrets/$hash"

                # Add it to the list of "desired files", so we can clean up any
                # no-longer-needed files at the end.
                echo '${filename}' >> /run/agenix-derived-secrets/desired-files

                # Now, generate that derived file.
                mkdir -p "$(dirname '${filename}')"
                ${generator.script} > '${filename}'

                chmod ${generator.mode} '${filename}'
                chown ${generator.user}:${generator.group} '${filename}'
              ''
            )
            cfg.rooter.derivedSecrets)
      ) + (
        ''
          # Finally, remove any no-longer-needed files.
          rm -f /run/agenix-derived-secrets/actual-files
          for f in /run/agenix-derived-secrets/*; do
            if [ -L "$f" ]; then
              readlink -f "$f" >> /run/agenix-derived-secrets/actual-files
            fi
          done

          comm -23 <(sort /run/agenix-derived-secrets/actual-files) <(sort /run/agenix-derived-secrets/desired-files) | while read -r filename; do
            echo "Cleaning up unneeded file: $filename" >/dev/stderr
            hash=$(echo -n "$filename" | md5sum | cut -f1 -d " ")
            rm "/run/agenix-derived-secrets/$hash"
            rm -f "$filename"
          done
        ''
      );
    };
  };

  options.age = {
    # Extend age.secrets with new options
    secrets = mkOption {
      type = types.attrsOf (types.submodule (submod: {
        options = {
          id = mkOption {
            type = types.str;
            default = submod.config._module.args.name;
            readOnly = true;
            description = mdDoc "The true identifier of this secret as used in `age.secrets`.";
          };

          rooterEncrypted = mkOption {
            type = types.nullOr types.str;
            default = null;
            example = literalExpression "-----BEGIN AGE ENCRYPTED FILE----- [...] -----END AGE ENCRYPTED FILE-----";
            description = mdDoc ''
              A secret encrypted with `tools/encrypt`.

              This secret will automatically be reencrypted for hosts that use it,
              and the resulting host-specific .age file will be set as actual
              `file` attribute. So naturally this is mutually exclusive with
              specifying `file` directly.

              If you want to avoid having a `secrets.nix` file and only use
              reencrypted secrets, you should always use this option instead of
              `file`.
            '';
          };
        };
        config = {
          file = mkIf (submod.config.rooterEncrypted != null) (rooter-lib.generatedSecretStorePath config submod.config);
        };
      }));
    };

    rooter = {
      hostPubkey = mkOption {
        type = with types; str;
        description = mdDoc ''
          The age public key to use as a recipient when rekeying. This must be the public key itself in string form.

          Note: this must *not* be a private key, it'll end up in the public nix store!
        '';
        example = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI.....";
      };
      generatedForHostDir = mkOption {
        type = with types; path;
        default = [ ];
        description = mdDoc ''
          The directory to store the re-encrypted (aka "rekeyed") secrets in.
          It's ok for this directory to be shared between different hosts, but
          not required.

          It is expected that you commit this directory to version control, and
          then you can do entirely pure builds.

          Don't manage the files in this directory by hand. Just run `nix run
          .#agenix-rooter-generate` to regenerate the files as necessary (when
          changing secrets, or a host's public key).
        '';
      };

      derivedSecrets = mkOption {
        default = { };
        type = with types; attrsOf (submodule {
          options = {
            script = mkOption {
              type = with types; path;
              description = mdDoc "The script to run.";
            };

            mode = mkOption {
              type = types.str;
              default = "0400";
              example = "0644";
              description = lib.mdDoc "The permissions to apply to the generated file.";
            };

            user = mkOption {
              default = "0";
              type = types.str;
              description = lib.mdDoc "User (name or id) of created file.";
            };

            group = mkOption {
              default = "0";
              type = types.str;
              description = lib.mdDoc "Group (name or id) of created file.";
            };
          };
        });
        description = mdDoc ''
          A set of scripts that read in secrets and print to stdout. Useful for
          embedding secrets into larger configuration files without having to
          encrypt the whole configuration file just because it has a secret
          somewhere inside of it.

          These files are managed declaratively: that is, iif you stop
          declaring one of them, it will get deleted. However, any ancestor
          directories we created when initially creating the file will stay
          behind, even if removing the file means the their parent directory is
          now empty. (we could change this behavior, it was just easier to
          build it this way).
        '';
        example = literalExpression ''
          { " /etc/NetworkManager/system-connections/myssid.nmconnection ".script =
            '''
            echo " [ connection ] "
            ...
            [wifi-security]
            ...
            psk=$${cfg.secrets.myssid-password.path}
            ''';
          }
        '';
      };
    };
  };
}
