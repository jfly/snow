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
  # I find it pretty useful to do ad-hoc edits of `/etc/hosts`. I know this
  # isn't exactly reproducible, but I'll live with it.
  # Trick copied from
  # https://discourse.nixos.org/t/a-fast-way-for-modifying-etc-hosts-using-networking-extrahosts/4190
  environment.etc.hosts.mode = "0644";
  # Enable docker for the main user.
  virtualisation.docker.enable = true;
  users.users.${config.snow.user.name}.extraGroups = [ "docker" ];

  # Set up a local DNS server
  networking.resolvconf.useLocalResolver = true;
  services.dnsmasq = {
    enable = true;
    settings = {
      address = "/local.honor/127.0.0.1";
    };
  };

  # Set up ssh agent
  programs.ssh = {
    startAgent = true;
    enableAskPassword = true;
    # Switch from the old school looking default askpass program to gnome
    # seahorse's much prettier one.
    askPassword = "${pkgs.gnome.seahorse}/libexec/seahorse/ssh-askpass";
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

  # QEMU emulation used for compiling for other architectures.
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  # Needed by ~/bin/allprocs
  programs.sysdig.enable = true;

  environment.systemPackages = with pkgs; [
    ### Version control
    git

    ### Network
    nm-vpn-add
    curl
    wget
    whois
    netcat
    traceroute
    dnsutils # provides nslookup
    sipcalc # an advanced console based ip subnet calculator
    lsof
    wireshark
    tcpdump

    ### Python
    socat # Multipurpose relay (useful with remote-pdb!)

    ### Misc
    gdb

    ### Honor
    # server-config
    (vagrant.override {
      # I'm having trouble installing the vagrant-aws plugins with this setting enabled.
      withLibvirt = false;
    })
    gnupg
    openssl
    # dev setup scripts
    amazon-ecr-credential-helper
    # external-web
    nginx
  ];
}
