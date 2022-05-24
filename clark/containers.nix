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
  state-backup = pkgs.writeShellScriptBin "state-backup" ''
    export PATH=$PATH:${pkgs.findutils}/bin
    export PATH=$PATH:${pkgs.gnutar}/bin

    # Ensure these files are read + writeable by group.
    umask 002

    # Create a backup with today's date
    backup=/mnt/media/backups/clark-state-$(date -I).tar
    wip_backup=$backup.wip
    tar cfp "$wip_backup" /state
    mv "$wip_backup" "$backup"

    # Remove backups more than 10 days old
    find /mnt/media/backups -type f -mtime +10 -delete
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

  # Do a daily backup of /state
  # TODO: also do mysqldump/pg_dump to deal with the fact that this is not
  # atomic and databases are probably finnicky
  systemd = {
    timers.state-backup = {
      description = "/state backup timer";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        Unit = "state-backup.service";
      };
    };
    services.state-backup = {
      description = "/state backup";
      enable = true;
      script = "${state-backup}/bin/state-backup";
    };
  };
}
