{ flake, ... }:

let
  identities = flake.lib.identities;
in
{
  users = {
    mutableUsers = false;
    users.kent = {
      isNormalUser = true;
      openssh.authorizedKeys.keys = [
        identities.jfly
      ];
      extraGroups = [
        "wheel"
        "media" # access to /mnt/nexus
      ];
    };
  };
}
