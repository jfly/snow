{ config, ... }:

{
  services.printing.enable = true;
  # services.printing.logLevel = "debug";
  # From https://nixos.wiki/wiki/Printing#Client_.28Linux.29
  services.avahi.enable = true;
  services.avahi.nssmdns4 = true;

  # https://nixos.wiki/wiki/Scanners
  # Ok, not technically printers, but they're in a similar family :p
  hardware.sane.enable = true;
  users.users.${config.snow.user.name}.extraGroups = [
    "scanner"
    "lp"
  ];
}
