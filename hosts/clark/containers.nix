{ config, pkgs, ... }:

{
  age.secrets.container-registry-password.rooterEncrypted = ''
    -----BEGIN AGE ENCRYPTED FILE-----
    YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBQQVRFTUlCZWx5Q2h3eTBV
    L1NPVzlCUkF0NXJHdGJHQ21RU241YWx6UVJVCkp3OXlqbTZPaDk2dXh4eHdrcW9z
    TDkvakZPNWNZRmtmWjN4T0syMHZyTVEKLS0tIHRFai9mbmg1d0NCTGtud3IrSmdM
    Mnh5R3BQanh5Z0E5SUY0dEpqZjRkQm8KCMOJ1z95tlc9BjFdqwDdKlk/fAqKMh9x
    ctwQ/vg5pVGjmqHbuHHtRsDuFXOn+OS1uEKc0w==
    -----END AGE ENCRYPTED FILE-----
  '';

  # Set up a kubernetes cluser with k3s
  systemd.services.k3s = {
    preStart = ''
      set -euo pipefail

      mkdir -p /etc/snow/k3s
      echo -n "
      configs:
        containers.snow.jflei.com:
          auth:
            username: k8s
            password: $(cat ${config.age.secrets.container-registry-password.path})
      " > /etc/snow/k3s/registries.yaml

      # This config comes from https://github.com/k3s-io/k3s/discussions/2997#discussioncomment-417679
      # It gets source IPs to show up correctly when going through proxies, but
      # maybe doesn't do the right thing for a multi-node k3s cluster? :shrug:,
      # we'll find out when that day comes.
      # TODO: look into MetalLB, it looks *dope*: https://metallb.universe.tf
      mkdir -p /var/lib/rancher/k3s/server/manifests/
      echo -n "apiVersion: helm.cattle.io/v1
      kind: HelmChartConfig
      metadata:
        name: traefik
        namespace: kube-system
      spec:
        valuesContent: |-
          image:
            # TODO: extract docker.io once the registry field is merged up
            # https://github.com/traefik/traefik-helm-chart/commit/24cf0ee00338970ab7f3cae03eaf2edb451632f7
            repository: docker.io/jfly/traefik
            # TODO: switch back to regular image if
            # https://github.com/traefik/traefik/pull/10130 gets merged and
            # released (also remove overridden crd in `k8s/crds` and regenerate
            # pulumi crds).
            tag: "2.9.10-custom-status-code-for-ip-list-middleware@sha256:c73efc904a1a03fd43f5561660039b168491243a0a7b0d8ba541367c2177591f"
            pullPolicy: IfNotPresent
          additionalArguments:
            - '--accesslog'
            - '--log.level=INFO'
          service:
            spec:
              externalTrafficPolicy: Local
      " > /var/lib/rancher/k3s/server/manifests/z-traefik-get-real-ip.yaml
    '';
  };
  services.k3s = {
    enable = true;
    role = "server";
    extraFlags = "--private-registry /etc/snow/k3s/registries.yaml";
  };

  boot = {
    kernel.sysctl = {
      # The system seems to run out of watches and instances with k3s running.
      # Increase the limit to something much larger than the default.
      "fs.inotify.max_user_watches" = "1048576";
      "fs.inotify.max_user_instances" = "8192";
    };
  };
  environment.systemPackages = [ pkgs.k3s ];
}
