{ pkgs, ... }:

{
  # Set up a kubernetes cluster with `k3s`.
  systemd.services.k3s = {
    preStart = ''
      set -euo pipefail

      mkdir -p /etc/snow/k3s
      echo -n "
      mirrors:
        clark.ec:5000:
          endpoint:
            - 'http://clark.ec:5000'
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
    extraFlags = [
      "--private-registry /etc/snow/k3s/registries.yaml"
      "--tls-san clark.ec"
    ];
  };

  # Run a docker registry (see `--private-registry` where we teach `k3s` about this registry).
  services.dockerRegistry = {
    enable = true;
    listenAddress = "0.0.0.0";
    openFirewall = true;
  };

  boot = {
    kernel.sysctl = {
      # The system seems to run out of watches and instances with `k3s` running.
      # Increase the limit to something much larger than the default.
      "fs.inotify.max_user_watches" = "1048576";
      "fs.inotify.max_user_instances" = "8192";
    };
  };
  environment.systemPackages = [ pkgs.k3s ];
}
