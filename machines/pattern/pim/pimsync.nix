{
  lib,
  pkgs,
  config,
  ...
}:
let
  # TODO: port this to a proper nixos module (and upstream it to nixpkgs). Make
  # sure that you can extract the pairs and localPaths from the options.
  pairNames = [
    "jfly_cards"
    "ramfly_cards"
  ];
  localPaths = [
    "$HOME/pim/contacts/jfly"
    "$HOME/pim/contacts/ramfly"
  ];
  pimsyncConf = pkgs.writeTextFile {
    name = "pimsync.conf";
    text =
      # scfg
      ''
        status_path "~/.local/share/pimsync/status/"

        storage jfly_card_remote {
          type carddav
          url https://carddav.fastmail.com
          username me@jfly.fyi
          password {
            cmd cat ${config.clan.core.vars.generators.fastmail-jfly-app-password.files."password".path}
          }
        }
        storage jfly_card_local {
          type vdir/vcard
          path ~/pim/contacts/jfly
          fileext vcf
        }
        pair jfly_cards {
          storage_a jfly_card_local
          storage_b jfly_card_remote
          collections all
        	conflict_resolution cmd nvim -d
        }

        storage ramfly_card_remote {
          type carddav
          url https://carddav.fastmail.com
          username hello@ramfly.net
          password {
            cmd cat ${config.clan.core.vars.generators.fastmail-ramfly-app-password.files."password".path}
          }
        }
        storage ramfly_card_local {
          type vdir/vcard
          path ~/pim/contacts/ramfly
          fileext vcf
        }
        pair ramfly_cards {
          storage_a ramfly_card_local
          storage_b ramfly_card_remote
          collections all
        }
      '';
  };
  myPimsync = pkgs.symlinkJoin {
    inherit (pkgs.pimsync) name meta;
    paths = [ pkgs.pimsync ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/pimsync --add-flags "-c ${pimsyncConf}"
    '';
  };
in
{
  environment.systemPackages = [
    myPimsync
  ];
  systemd.user.services = lib.mkMerge (
    [
      {
        "pimsync@" = {
          scriptArgs = "%i";
          script = ''
            # This is a quick hack to ensure all local paths exist, because pimsyncer
            # won't create them for us.
            # Note: tere's a not-yet-accepted patch upstream that would implement
            # this behavior for us:
            # <https://lists.sr.ht/~whynothugo/vdirsyncer-devel/patches/58251>.
            # Hopefully that lands someday and we can remove this code.
            mkdir -p ${lib.escapeShellArgs localPaths}

            pair="$1"

            ${lib.getExe myPimsync} discover "$pair"
            exec ${lib.getExe myPimsync} daemon "$pair"
          '';
          serviceConfig = {
            # TODO: figure out how to make this type notify: <https://lists.sr.ht/~whynothugo/vdirsyncer-devel/%3CDDDNDRRZBFVM.38T0QW059IA24@jfly.fyi%3E>
            Type = "simple";
            Restart = "always";
          };
        };
      }
    ]
    # Note: we run each pair as a separate service as per
    # <https://pimsync.whynothugo.nl/advanced.html#one-instance-per-pair>.
    ++ (map (pairName: {
      "pimsync@${pairName}" = {
        overrideStrategy = "asDropin";
        wantedBy = [ "default.target" ];
      };
    }) pairNames)
  );
}
