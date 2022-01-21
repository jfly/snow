{ pkgs, ... }:

{
  # Hack copied from
  # https://discourse.nixos.org/t/docker-podman-network-create-nix/13569
  systemd.services."docker-network-clark" = {
    serviceConfig.Type = "oneshot";
    wantedBy = [ "ddocker-snow-web.service" "docker-home-assistant.service" ];
    script = ''
      ${pkgs.docker}/bin/docker network inspect clark > /dev/null 2>&1 || ${pkgs.docker}/bin/docker network create clark
    '';
  };

  virtualisation.oci-containers.containers = {
    snow-web = import ./snow-web { inherit pkgs; };
    home-assistant = import ./home-assistant {};
    wallabag = import ./wallabag { inherit pkgs; };
  };
}
