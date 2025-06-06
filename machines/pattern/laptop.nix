{
  config,
  pkgs,
  lib,
  ...
}:

{
  location.provider = "geoclue2";
  services.geoclue2.enable = true;

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
        ${lib.getExe pkgs.sudo} systemctl --machine ${config.snow.user.name}@ --user restart lid.service
      '';
    };
  };

  # Suspend my laptop on low power rather than letting it die.
  # It might then die while suspending (powering RAM isn't free), but normally
  # this happens just because I've forgotten to plug in my laptop, and this
  # just gives me a moment to plug in before I lose whatever I'm in the middle
  # of.
  # Interestingly, upstream `upower` really doesn't want you to use "Suspend".
  # I believe their fear is is that you'll run out of power while sleeping, and
  # risk filesystem corruption. I've been uncleanly letting my laptop die for
  # years and have never had a ext4 issue though, so I'm not very concerned.
  # The *best* thing to do would be to enable hibernation (which at time of
  # writing I have not done yet), and use HybridSleep, which combines the speed
  # of Suspend with the guarantees of Hibernation.
  services.upower = {
    enable = true;
    criticalPowerAction = "Suspend";
    allowRiskyCriticalPowerAction = true;
  };
}
