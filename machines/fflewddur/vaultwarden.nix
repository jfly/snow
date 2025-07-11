{
  # This is just a proxy.
  # TODO: actually port vaultwarden from k8s to nix.

  imports = [
    # TODO: remove once everything is switched over to `vaultwarden.mm`.
    {
      services.data-mesher.settings.host.names = [ "vw" ];
      services.nginx.virtualHosts."vw.mm" = {
        enableACME = true;
        forceSSL = true;

        locations."/" = {
          proxyPass = "https://vw.snow.jflei.com";
          # Disable `recommendedProxySettings` to avoid this Host header:
          # https://github.com/NixOS/nixpkgs/blob/d3d2d80a2191a73d1e86456a751b83aa13085d7d/nixos/modules/services/web-servers/nginx/default.nix#L108
          # This is because we need the receiving end (in this case, Traefik on
          # k8s) to know where to forward the request.
          recommendedProxySettings = false;
          extraConfig = ''
            proxy_set_header Host $proxy_host;
          '';
        };
      };
    }
  ];

  services.data-mesher.settings.host.names = [ "vaultwarden" ];
  services.nginx.virtualHosts."vaultwarden.mm" = {
    enableACME = true;
    forceSSL = true;

    locations."/" = {
      proxyPass = "https://vw.snow.jflei.com";
      # Disable `recommendedProxySettings` to avoid this Host header:
      # https://github.com/NixOS/nixpkgs/blob/d3d2d80a2191a73d1e86456a751b83aa13085d7d/nixos/modules/services/web-servers/nginx/default.nix#L108
      # This is because we need the receiving end (in this case, Traefik on
      # k8s) to know where to forward the request.
      recommendedProxySettings = false;
      extraConfig = ''
        proxy_set_header Host $proxy_host;
      '';
    };
  };
}
