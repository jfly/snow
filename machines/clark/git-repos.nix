{ flake, pkgs, ... }:
let
  inherit (flake.lib) identities;
in
{
  snow.backup = {
    paths = [ "/state/git" ];
  };

  # For remotes like `ssh://root@clark/state/git/<repo>.git`
  users.users.root = {
    openssh.authorizedKeys.keys = [
      identities.jfly
    ];
  };

  environment.systemPackages = [
    pkgs.git # Needed so we can push to repos hosted on this machine.
  ];
}
