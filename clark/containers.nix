{ pkgs, ... }:

let
  api_key = pkgs.deage.string ''
    -----BEGIN AGE ENCRYPTED FILE-----
    YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBQQVRFTUlCZWx5Q2h3eTBV
    L1NPVzlCUkF0NXJHdGJHQ21RU241YWx6UVJVCkp3OXlqbTZPaDk2dXh4eHdrcW9z
    TDkvakZPNWNZRmtmWjN4T0syMHZyTVEKLS0tIHRFai9mbmg1d0NCTGtud3IrSmdM
    Mnh5R3BQanh5Z0E5SUY0dEpqZjRkQm8KCMOJ1z95tlc9BjFdqwDdKlk/fAqKMh9x
    ctwQ/vg5pVGjmqHbuHHtRsDuFXOn+OS1uEKc0w==
    -----END AGE ENCRYPTED FILE-----
  '';
  k3s_registries_conf = pkgs.writeText "registries.yaml" ''
    configs:
      containers.clark.snowdon.jflei.com:
        auth:
          username: k8s
          password: ${api_key}
  '';
in
{
  # Hack copied from
  # https://discourse.nixos.org/t/docker-podman-network-create-nix/13569
  systemd.services."docker-network-clark" = {
    serviceConfig.Type = "oneshot";
    requiredBy = [ "docker-snow-web.service" "docker-home-assistant.service" ];
    script = ''
      export PATH=${pkgs.docker}/bin:$PATH
      docker network inspect clark > /dev/null 2>&1 || docker network create clark
    '';
  };

  virtualisation.oci-containers.containers = {
    snow-web = import ./snow-web { inherit pkgs; };
    home-assistant = import ./home-assistant {};
  };

  # Set up a kubernetes cluser with k3s
  services.k3s = {
      enable = true;
      role = "server";
      extraFlags = "--private-registry ${k3s_registries_conf}";
  };
  environment.systemPackages = [ pkgs.k3s ];
}
