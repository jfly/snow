{ config, lib, pkgs, modulesPath, ... }:

let
  inherit
    (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    ;

  cfg = config.services.kodi-colusita;

  identities = import ../../../shared/identities.nix;
  media = pkgs.callPackage ./media {
    deviceName = config.networking.hostName;
  };
  myKodiWithPackages = pkgs.kodi.withPackages (p: [ p.a4ksubtitles media ]);

  # This is unfortunate: it just doesn't seem to be possible to set some kodi
  # settings without creating files in the ~/.kodi/userdata/addon_data
  # directory. So, we wrap kodi to give us an opportunity to do that.
  genKodiAddonData = pkgs.callPackage ./gen-kodi-addon-data { };
  myKodi = pkgs.symlinkJoin {
    name = "kodi";
    paths = [ myKodiWithPackages ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/kodi \
          --run "${genKodiAddonData}/gen-kodi-addon-data.sh"
    '';
  };
in

{
  options.services.kodi-colusita = {
    enable = mkEnableOption "kodi-colusita";
    startOnBoot = mkOption {
      type = types.bool;
      description = "Whether to start kodi on boot";
      default = false;
    };
    sshIdentityPath = mkOption {
      type = types.str;
      description = "Path to ssh identity to connect to clark.";
      example = "/run/secrets/id_rsa";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ myKodi ];

    programs.ssh.knownHosts = {
      "clark.snow.jflei.com" = {
        publicKey = identities.clark;
      };
    };

    fileSystems."/mnt/colusita" = {
      device = "media-ro@clark.snow.jflei.com:/mnt/media";
      fsType = "sshfs";
      options = [
        "ro"
        "x-systemd.automount"
        "noauto"
        "x-systemd.requires=network-online.target"
        "allow_other"
        "IdentityFile=${cfg.sshIdentityPath}"
      ];
    };

    systemd.user.services = {
      "kodi" = {
        enable = cfg.startOnBoot;
        wantedBy = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        serviceConfig = {
          ExecStart = "${myKodi}/bin/kodi";
        };
      };
    };
  };
}
