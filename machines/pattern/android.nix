{ config, pkgs, ... }:

{
  # From <https://wiki.nixos.org/wiki/KDE_Connect>
  # NixOS has a `programs.kdeconnect.enable` which doesn't work. Confusingly,
  # there are 2 very different versions of kdeconnect packaged in nixpkgs.
  # Neither of them seem to work for me without running `kdeconnectd` as a user
  # daemon (perhaps that comes baked into the KDE desktop environment
  # (Plasma)?). Home Manager has this set up, but nixpkgs does not.
  home-manager.users.${config.snow.user.name}.services.kdeconnect.enable = true;
  networking.firewall =
    let
      allowedPortRange = {
        from = 1714;
        to = 1764;
      };
    in
    {
      allowedTCPPortRanges = [ allowedPortRange ];
      allowedUDPPortRanges = [ allowedPortRange ];
    };

  programs.adb.enable = true;
  users.users.${config.snow.user.name}.extraGroups = [ "adbusers" ];

  environment.systemPackages = with pkgs; [
    scrcpy
  ];
}
