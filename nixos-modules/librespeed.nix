# Quick and dirty NixOS module just to get this working.
# There's a proper module in the works in
# <https://github.com/NixOS/nixpkgs/pull/345505>. (I'm not using it because (at
# time of writing), it conflicts with main.)
{
  pkgs,
  config,
  lib,
  flake',
  ...
}:

let
  settings = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/librespeed/speedtest-go/7001fa4fa52945cbc6d4c32200bbcce7bbf6145c/settings.toml";
    hash = "sha256-BidVTyVFsVQ0ahIEae9xSwl0Pk3mPgIbJok8X8gLoUs=";
  };
  cfg = config.services.librespeed;
in
{
  options.services.librespeed = {
    enable = lib.mkEnableOption "LibreSpeed server";
    package = lib.mkPackageOption flake'.packages "librespeed-go" { };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8989; # https://github.com/librespeed/speedtest-go/blob/7001fa4fa52945cbc6d4c32200bbcce7bbf6145c/settings.toml#L4
      readOnly = true;
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.librespeed = {
      description = "LibreSpeed server daemon";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "exec";
        Restart = "on-failure";
        ExecStart = "${lib.getExe cfg.package} -c ${settings}";
      };
    };
  };
}
