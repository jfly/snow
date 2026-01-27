{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (config.snow) services;
  dataDir = "/var/lib/soju";
  ports.ircTls = 6697;
in
{
  # To add users:
  # ```console
  # fflewddur# sojudb create-user <soju username> -admin
  # fflewddur# systemctl restart soju
  # ```
  services.soju = {
    enable = true;
    hostName = services.irc.fqdn;
    listen = [ ":${toString ports.ircTls}" ];
    # Explicitly specifying the db is necessary not for the soju server (it
    # defaults to `./soju.db`, which is exactly the right place as
    # `/var/lib/soju` is the working directory for the systemd service.
    # We specify it explicitly so the `sojudb` cli works.
    extraConfig = ''
      db sqlite3 ${dataDir}/soju.db
    '';

    tlsCertificate = "/run/credentials/${config.systemd.services.soju.name}/cert.pem";
    tlsCertificateKey = "/run/credentials/${config.systemd.services.soju.name}/key.pem";
  };

  systemd.services.soju.serviceConfig = {
    LoadCredential = [
      "cert.pem:${config.security.acme.certs.${services.irc.fqdn}.directory}/cert.pem"
      "key.pem:${config.security.acme.certs.${services.irc.fqdn}.directory}/key.pem"
    ];

    # nixpkgs's implementation of `ExecReload` for Soju sends a SIGHUP to
    # the service, which causes the service to reload its config and re-read
    # any certificates mentioned in the config. *Unfortunately*, systemd does
    # not reload the `LoadCredential`s above, so the service just re-reads the
    # exact same (outdated) credentials.
    # AFAICT, the best fix for now is to restart the service rather than reload
    # it. This causes systemd to reload the credentials in `LoadCredential`,
    # but does mean we have a brief outage :cry:.
    # See <https://github.com/systemd/systemd/issues/21099> for hope that
    # systemd will allow reloading `LoadCredential`s someday.
    ExecReload = lib.mkForce null;
  };

  # Note that we use nginx to generate a cert because nginx is capable
  # of passing the "host a file" HTTP challenge.
  snow.services.irc.nginxExtraConfig = ''
    add_header Content-Type text/plain;
    return 200 "There's a Soju IRC bouncer here at :${toString ports.ircTls}";
  '';
  security.acme.certs.${services.irc.fqdn}.reloadServices = [ config.systemd.services.soju.name ];

  # Allow traffic only from the overlay network.
  networking.firewall.interfaces.${config.snow.subnets.overlay.interface}.allowedTCPPorts =
    builtins.attrValues ports;

  environment.systemPackages = [
    (pkgs.symlinkJoin {
      inherit (pkgs.soju) name;
      paths = [ pkgs.soju ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/sojudb \
          --add-flags "-config ${config.services.soju.configFile}"
      '';
    })
  ];

  snow.backup.paths = [ dataDir ];
}
