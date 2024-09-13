{ flake, config, lib, pkgs, modulesPath, ... }:

let
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    ;
  inherit (builtins)
    concatStringsSep
    ;

  cfg = config.services.kodi-colusita;

  identities = flake.lib.identities;
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
    environment.systemPackages = [ myKodi ] ++ (with pkgs;
      [ sshfs ]);

    programs.ssh.knownHosts = {
      "clark.snow.jflei.com" = {
        publicKey = identities.clark;
      };
    };

    systemd.mounts = [
      {
        where = "/mnt/colusita";
        what = "media-ro@clark.snow.jflei.com:/mnt/media";
        type = "fuse.sshfs";
        startLimitBurst = 0; # keep retrying indefinitely (https://www.freedesktop.org/software/systemd/man/latest/systemd.unit.html#StartLimitIntervalSec=interval)
        requires = [ "network-online.target" ];
        options = concatStringsSep "," [
          "ro"
          "noauto"
          "allow_other"
          "IdentityFile=${cfg.sshIdentityPath}"
          # Reconnect automatically if the connection drops.
          "reconnect"
          "ServerAliveInterval=15"
          "ServerAliveCountMax=3"
        ];
      }
    ];
    systemd.automounts = [
      {
        where = "/mnt/colusita";
        wantedBy = [ "multi-user.target" ];
      }
    ];

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
