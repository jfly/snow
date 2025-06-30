{ flake, ... }:
{
  imports = [
    flake.nixosModules.shared
    flake.nixosModules.monitoring
    ./boot.nix
    ./nginx.nix
    ./network.nix
    ./gpu.nix
    ./nas.nix
    ./backup
    ./jellyfin.nix
    ./cryptpad.nix
    ./syncthing.nix
    ./vpn
    ./prometheus
    ./grafana.nix
    ./healthcheck.nix
    ./immich.nix
    ./remote-desktop.nix
    ./step-ca.nix
    ./vaultwarden.nix
    ./audiobookshelf.nix
    ./nextcloud.nix
  ];

  networking.hostName = "fflewddur";

  # i18n stuff
  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";
  services.xserver.xkb.layout = "us";

  # Enable ssh.
  services.openssh.enable = true;

  #<<< hack >>>
  services.data-mesher.settings.host.names = [ "baconipsum" ];
  services.nginx.virtualHosts."baconipsum.mm" = {
    enableACME = true;
    forceSSL = true;

    locations."/" = {
      proxyPass = "https://baconipsum.com";
      # Disable `recommendedProxySettings` to avoid this Host header:
      # https://github.com/NixOS/nixpkgs/blob/d3d2d80a2191a73d1e86456a751b83aa13085d7d/nixos/modules/services/web-servers/nginx/default.nix#L108
      # This is because we need the receiving end to know where to forward the
      # request.
      recommendedProxySettings = false;
      extraConfig = ''
        proxy_set_header Host $proxy_host;
      '';
    };
  };
  #<<< end hack >>>
}
