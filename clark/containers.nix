{ pkgs, ... }:

let
  password = pkgs.deage.string ''
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
          password: ${password}
  '';
in
{
  # Set up a kubernetes cluser with k3s
  services.k3s = {
      enable = true;
      role = "server";
      extraFlags = "--private-registry ${k3s_registries_conf}";
  };
  system.activationScripts = {
      # This config comes from https://github.com/k3s-io/k3s/discussions/2997#discussioncomment-417679
      # It gets source IPs to show up correctly when going through proxies, but
      # maybe doesn't do the right thing for a multi-node k3s cluster? :shrug:,
      # we'll find out when that day comes.
      k3s_config = ''
        echo "apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: traefik
  namespace: kube-system
spec:
  valuesContent: |-
    externalTrafficPolicy: Local" > /var/lib/rancher/k3s/server/manifests/traefik.z.yaml
      '';
  };
  environment.systemPackages = [ pkgs.k3s ];
}
