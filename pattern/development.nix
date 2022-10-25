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
  docker-conf = pkgs.writeTextDir "config.json"
    (builtins.toJSON {
      "credHelpers" = {
        "900965112463.dkr.ecr.us-west-2.amazonaws.com" = "ecr-login";
      };
      "auths" = {
        "containers.clark.snowdon.jflei.com" = {
          "auth" = pkgs.deage.string ''
            -----BEGIN AGE ENCRYPTED FILE-----
            YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBtdUNCWjkrU1VqVndNMDhF
            SjN0emN4UHZnaWJ1MUNXOC9hUytheE8xTDJFCk1OOHpidm0zbGd5d3BFaVZKSU51
            NXRuRlJRNFRYRUxNR2g1Y3ZMTEpJaWsKLS0tIHBGTWRUQjh6bGc4WWJDbThOM1FJ
            ZUFYeWc0a1pXUXliLy9IN3E4czFmWWsKa5YmXKdvYuW9Dm/z9KE+SCvjXZYzq+Up
            naqZkJUsz/p4wjD/jvBYADdyFf76HD7yPXU18ulbwq9gTU3SaK2PzQ==
            -----END AGE ENCRYPTED FILE-----
          '';
        };
      };
      "detachKeys" = "ctrl-^,q";
    });
  docker-with-conf = pkgs.symlinkJoin {
    name = "docker";
    paths = [ pkgs.docker ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/docker \
        --add-flags "--config=${docker-conf}"
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
  virtualisation.docker = {
    enable = true;
    package = docker-with-conf;
  };
  users.users.${config.snow.user.name}.extraGroups = [ "docker" ];

  # Set up a local DNS server
  networking.resolvconf.useLocalResolver = true;
  services.dnsmasq.enable = true;
  services.dnsmasq.extraConfig = ''
    address=/local.honor/127.0.0.1
  '';

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
