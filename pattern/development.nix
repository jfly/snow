{ config, pkgs, lib, ... }:

let
  nm-vpn-add = pkgs.callPackage ../shared/nm-vpn-add { };
  # Reconfigure gpg-agent to have a longer lived cache: up to 8 hours after
  # last used, but the cache also expires when it is 8 hours old, even if it
  # has been used recently.
  gpg-agent_conf = pkgs.writeTextFile {
    name = "gpg-agent.conf";
    text = ''
      default-cache-ttl ${toString (12 * 3600)}
      max-cache-ttl ${toString (12 * 3600)}
    '';
  };
in
{
  # Enable docker for the main user.
  virtualisation.docker.enable = true;
  users.users.${config.snow.user.name}.extraGroups = [ "docker" ];

  # Set up ssh agent
  programs.ssh = {
    startAgent = true;
    enableAskPassword = true;
    extraConfig = ''
      AddKeysToAgent yes
    '';
  };
  environment.variables.SSH_ASKPASS_REQUIRE = "prefer";

  # Enable gpg agent
  programs.gnupg.agent.enable = true;
  systemd.user.services.gpg-agent =
    let cfg = config.programs.gnupg;
    in
    {
      serviceConfig.ExecStart = [
        ""
        ''
          ${cfg.package}/bin/gpg-agent --supervised \
            --pinentry-program ${pkgs.pinentry.${cfg.agent.pinentryFlavor}}/bin/pinentry \
            --options ${gpg-agent_conf}
        ''
      ];
    };

  environment.systemPackages = with pkgs; [
    ### Network
    nm-vpn-add
    curl
    wget
    whois
    netcat
    traceroute
    dnsutils # Provides nslookup
    sipcalc # an advanced console based ip subnet calculator

    ### Honor
    # server-config
    (vagrant.override {
      # I'm having trouble installing the vagrant-aws plugins with this setting enabled.
      withLibvirt = false;
    })
    gnupg
    openssl
    amazon-ecr-credential-helper
  ];
}
