{ ... }:

{
  services.printing.enable = true;
  # From https://nixos.wiki/wiki/Printing#Client_.28Linux.29
  services.avahi.enable = true;
  services.avahi.nssmdns = true;

  hardware.printers.ensurePrinters = [
    {
      name = "lloyd";
      location = "ram office";
      description = "color laser printer";
      deviceUri = "ipps://lloyd/ipp/print";
      model = "everywhere";
    }
  ];

  # https://nixos.wiki/wiki/Scanners
  # Ok, not technically printers, but they're in a similar family :p
  hardware.sane.enable = true;
  users.users.${config.snow.user.name}.extraGroups = [ "scanner" "lp" ];
}
