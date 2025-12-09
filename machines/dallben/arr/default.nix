{
  imports = [
    ./wireguard.nix
    ./mnt-media.nix
    ./transmission.nix
  ];

  services.sonarr = {
    enable = true;
    group = "media";
  };
}
