{ flake', ... }:
{
  environment.systemPackages = [ flake'.packages.beets ];
}
