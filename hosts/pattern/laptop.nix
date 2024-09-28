{
  config,
  pkgs,
  lib,
  ...
}:

let
  # TODO: consolidate with pattern/desktop/.
  restart-user-service = pkgs.writeShellScript "restart-user-service" ''
    user=$1
    service=$2
    uid=$(id -u $user)
    export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus"
    ${pkgs.sudo}/bin/sudo -u "$1" --preserve-env=DBUS_SESSION_BUS_ADDRESS ${pkgs.systemd}/bin/systemctl --user restart "$service"
  '';
in
{
  location.provider = "geoclue2";
  services.geoclue2 = {
    enable = true;
    # Workaround for <https://github.com/NixOS/nixpkgs/issues/321121>.
    geoProviderUrl = "https://beacondb.net/v1/geolocate";
  };

  # Keep the system timezone in sync as we travel the world. Needs Geoclu in
  # order to know where we are on Earth.
  services.automatic-timezoned.enable = true;

  # Shift the color temperature of the screen throughout the day. Needs geoclue
  # in order to know where we are on Earth.
  services.redshift.enable = true;

  systemd.user.services = {
    "lid" = {
      enable = true;
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      # Right now, I often temporarily hack on lid.sh and it would be nice to
      # not have to rebuild to pull those changes in. Once I've got a better
      # sense of what exactly lid.sh should do, I think it would make sense to
      # get rid of all this PATH hacking in favor of a simple invocation of a
      # script in a nix derivation.
      #
      # Hack to allow the user's PATH to percolate through.
      # stage2ServiceConfig in nixos/lib/systemd-lib.nix really wants to give
      # us a default PATH. However, dunst currently uses xdg-open to fire up a
      # browser, and *that* needs a PATH with whatever default browser we've
      # got set up. So, it's better to use systemctl's "user environment block"
      # (populated by xsessionWrapper when it calls `systemctl
      # import-environment`), because that'll have the right PATH and BROWSER,
      # but to inherit that PATH, we have to make sure we don't specify a PATH
      # whatsoever.
      path = lib.mkForce [ ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "/home/${config.snow.user.name}/bin/lid.sh";
      };
    };
  };
  services.acpid = {
    enable = true;
    handlers.lid = {
      event = "button/lid.*";
      action = ''
        ${restart-user-service} ${config.snow.user.name} lid
      '';
    };
  };
}
