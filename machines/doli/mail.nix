{
  flake,
  flake',
  inputs,
  config,
  pkgs,
  ...
}:

{
  imports = [
    inputs.simple-nixos-mailserver.nixosModule
    ./postsrsd.nix
    flake.nixosModules.email-credentials-alerts
  ];

  mailserver = {
    enable = true;
    x509.useACMEHost = config.mailserver.fqdn;
    stateVersion = 3; # https://nixos-mailserver.readthedocs.io/en/latest/migrations.html

    # Keep in sync with `iac/pulumi/app/dns.py`
    fqdn = "mail.playground.jflei.com";
    domains = [ "playground.jflei.com" ];

    loginAccounts = {
      "jfly@playground.jflei.com".hashedPasswordFile =
        config.clan.core.vars.generators.mail-jfly.files."password.bcrypt".path;
      "jeremy@playground.jflei.com".hashedPasswordFile =
        config.clan.core.vars.generators.mail-jeremy.files."password.bcrypt".path;
      "alerts@playground.jflei.com".hashedPasswordFile =
        config.clan.core.vars.generators.mail-alerts.files."password.bcrypt".path;
    };

    dkimDomainPrivateKeyFiles = {
      "playground.jflei.com" =
        config.clan.core.vars.generators."dkim-playground.jflei.com.${config.mailserver.dkimSelector}".files."key".path;
    };
  };

  services.postfix.settings.main.virtual_alias_maps = [
    # Extending https://github.com/NixOS/nixpkgs/blob/a9fe4d6d8ccde780e872ed1446f3746498152663/nixos/modules/services/mail/postfix.nix#L833C87-L833C108
    "hash:/etc/postfix/virtual-jfly-test"
  ];

  services.postfix.mapFiles.virtual-jfly-test = pkgs.writeText "postfix-virtual-jfly" ''
    me@playground.jflei.com jfly@playground.jflei.com, jeremyfleischman+subscriber@gmail.com
  '';

  # Note that we use nginx to generate a cert because nginx is capable
  # of passing the "host a file" HTTP challenge.
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;

    virtualHosts.${config.mailserver.fqdn} = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        extraConfig = ''
          add_header Content-Type text/plain;
          return 200 "Welcome";
        '';
      };
    };
  };
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  # Our step-ca module (used by every machine in the cluster) defaults to
  # querying our self-hosted step-ca for certs. However, that ACME server is
  # only able to generate certs for our "fake" overlay domain. For "real"
  # domain names, we still need to talk to Let's Encrypt.
  # TODO: investigate what would be involved in configuring ACME server globs/regexes.
  security.acme.certs.${config.mailserver.fqdn} = {
    server = "https://acme-v02.api.letsencrypt.org/directory";
    renewInterval = "daily";
  };

  clan.core.vars.generators.mail-jfly = {
    files."password".deploy = false;
    files."password.bcrypt" = { };
    runtimeInputs = with pkgs; [
      coreutils
      xkcdpass
      mkpasswd
    ];
    script = ''
      xkcdpass --numwords 4 --delimiter - | tr -d "\n" > $out/password
      mkpasswd --method=bcrypt --stdin < $out/password > $out/password.bcrypt
    '';
  };

  clan.core.vars.generators.mail-jeremy = {
    files."password".deploy = false;
    files."password.bcrypt" = { };
    runtimeInputs = with pkgs; [
      coreutils
      xkcdpass
      mkpasswd
    ];
    script = ''
      xkcdpass --numwords 4 --delimiter - | tr -d "\n" > $out/password
      mkpasswd --method=bcrypt --stdin < $out/password > $out/password.bcrypt
    '';
  };

  clan.core.vars.generators."dkim-playground.jflei.com.${config.mailserver.dkimSelector}" = {
    files."key" = {
      owner = config.services.rspamd.user;
      group = config.services.rspamd.group;
    };
    files."txt".secret = false;
    runtimeInputs = with pkgs; [
      coreutils
      opendkim
      (pkgs.writers.writePython3Bin "parse-bindfile" { libraries = [ flake'.packages.zonefile-parser ]; }
        /* python */ ''
          import fileinput
          import zonefile_parser

          with fileinput.input() as f:
              content = "".join(f)
              records = zonefile_parser.parse(content)

              for record in records:
                  print(record.rdata['value'])
        ''
      )
    ];
    script = ''
      opendkim-genkey --selector="${config.mailserver.dkimSelector}" --domain="playground.jflei.com" --bits=1024
      mv "${config.mailserver.dkimSelector}.private" $out/key
      parse-bindfile "${config.mailserver.dkimSelector}.txt" > $out/txt
    '';
  };
}
