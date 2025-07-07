{ pkgs, ... }:
{
  # https://wiki.nixos.org/wiki/Waydroid
  # Once deployed, run `sudo waydroid init` to fetch Waydroid image.
  # And to run the thing: `cage waydroid show-full-ui`.
  virtualisation.waydroid.enable = true;
  environment.systemPackages = [ pkgs.cage ];
}
