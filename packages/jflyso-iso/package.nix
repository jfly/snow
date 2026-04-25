# Patterned off of https://wiki.nixos.org/wiki/Creating_a_NixOS_live_CD

{ flake }:

let
  sys = flake.nixosConfigurations.jflyso.extendModules {
    modules = [
      (
        { modulesPath, ... }:
        {
          imports = [ "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix" ];

          # Clan disables this on systems with swraid enabled. I don't care, I
          # want it enabled anyways:
          # <https://git.clan.lol/clan/clan-core/src/commit/34128114bd86d8f6b4e0148be61ee45984bc78bc/nixosModules/clanCore/defaults.nix#L18>.
          boot.initrd.systemd.enable = true;

          # The default compression algorithm produces the smallest images, but takes a *while*.
          isoImage.squashfsCompression = "gzip -Xcompression-level 1";
        }
      )
    ];
  };
in

sys.config.system.build.isoImage
