{ flake', ... }:
{
  environment.systemPackages = [ flake'.packages.khal ];
}
