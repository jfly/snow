{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    ### PDF
    evince
  ];
  xdg.mime.defaultApplications = {
    "application/pdf" = "org.gnome.Evince.desktop";
  };
}
