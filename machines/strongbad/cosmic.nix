{
  # https://wiki.nixos.org/wiki/COSMIC
  services.displayManager.cosmic-greeter.enable = true;
  services.desktopManager.cosmic.enable = true;
  services.system76-scheduler.enable = true;

  services.displayManager.autoLogin = {
    enable = true;
    user = "mary";
  };
}
