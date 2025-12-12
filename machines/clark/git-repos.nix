{ pkgs, ... }:
{
  snow.backup = {
    paths = [ "/state/git" ];
  };

  environment.systemPackages = [
    pkgs.git # Needed so we can push to repos hosted on this machine.
  ];
}
