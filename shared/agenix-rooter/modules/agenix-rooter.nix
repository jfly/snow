nixpkgs:
{ lib, options, config, pkgs, ... }:

let
  inherit
    (lib)
    assertMsg
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
in
{
  config = { };

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
    };
  };
}
