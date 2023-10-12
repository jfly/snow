{ config, pkgs, lib, ... }:

let
  nm-vpn-add = pkgs.callPackage ../shared/nm-vpn-add { };
  mfa = pkgs.callPackage ../shared/mfa { };
  h4-cli = pkgs.rustPlatform.buildRustPackage rec {
    pname = "cli";
    # TODO: find a better way of keeping this up to date. Perhaps turn upstream
    # into a flake?
    version = "0.0.32";

    src = builtins.fetchGit {
      url = "git@github.com:joinhonor/cli.git";
      ref = "refs/tags/${version}";
      rev = "5e2baba929e96c7967c97cfc0bca79a21cc5b69e";
    };

    cargoHash = "sha256-93lVnnIOVYuRk6lBdbcUnWqtk5qGaeeF5DwRgRdysvw=";

    # I'm not sure if this belongs in configurePhase (or even if it belongs in this package).
    # I originally tried adding it to installPhase, but that didn't work
    # because I couldn't figure out how to invoke the original installPhase.
    configurePhase = ''
      # Copy shell completions
      mkdir -p $out/share/zsh/site-functions
      cp completions/_honor $out/share/zsh/site-functions/_honor
    '';

    meta = with lib; {
      description = "A CLI to help streamline common Honor engineering tasks.";
      homepage = "https://github.com/joinhonor/cli";
    };
  };
  my-aws-vault = pkgs.symlinkJoin {
    name = "aws-vault";
    paths = [ pkgs.aws-vault ];
    postBuild =
      let
        wrapper = pkgs.writeShellScript "aws-vault-wrapper" ''
          # We don't actually use zenity, this is just a binary in ~/bin that aws-vault
          # recognizes the name of. See that script for some thoughts about a less
          # hacky approach to using a custom propmt.
          export AWS_VAULT_PROMPT="zenity"

          # TODO: Look into keyctl backend once
          # https://github.com/99designs/aws-vault/pull/1202 is merged.
          export AWS_VAULT_BACKEND="file"
          export AWS_VAULT_FILE_PASSPHRASE=$(cat ${config.age.secrets.aws-vault-file-passphrase.path})

          exec @og@ "$@"
        '';
      in
      ''
        og=$out/bin/.aws-vault-wrapped
        mv $out/bin/aws-vault $og
        cp ${wrapper} $out/bin/aws-vault
        substituteInPlace $out/bin/aws-vault \
          --replace "@og@" $og
      '';
  };
in
{
  options = {
    snow = {
      enable-h4 = lib.mkOption {
        type = lib.types.bool;
        description = lib.mdDoc "Whether or not to enable h4 features (which requires private git credentials)";
        default = true;
      };
    };
  };

  config = {
    # I find it pretty useful to do ad-hoc edits of `/etc/hosts`. I know this
    # isn't exactly reproducible, but I'll live with it.
    # Trick copied from
    # https://discourse.nixos.org/t/a-fast-way-for-modifying-etc-hosts-using-networking-extrahosts/4190
    environment.etc.hosts.mode = "0644";
    # Enable docker for the main user.
    virtualisation.docker.enable = true;
    virtualisation.docker.daemon.settings = {
      # Override default docker DNS in order to implement a
      # `host.docker.internal` domain.
      # As of 2023, it appears there's no good, consistent way of speaking to the
      # host on both macOS and Linux. Note: adding an entry to the containerized
      # `/etc/hosts` is not good enough, as some stuff like nginx actually ignore
      # /etc/hosts:
      # https://github.com/NginxProxyManager/nginx-proxy-manager/issues/259. For more information:
      # - https://stackoverflow.com/questions/48546124/what-is-linux-equivalent-of-host-docker-internal
      # - https://sam-ngu.medium.com/connecting-to-docker-host-mysql-from-docker-container-linux-ubuntu-766e526542fdd
      dns = [ "172.17.0.1" ];
    };
    users.users.${config.snow.user.name}.extraGroups = [ "docker" ];

    age.secrets.snow-containers-auth.rooterEncrypted = ''
      -----BEGIN AGE ENCRYPTED FILE-----
      YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBtdUNCWjkrU1VqVndNMDhF
      SjN0emN4UHZnaWJ1MUNXOC9hUytheE8xTDJFCk1OOHpidm0zbGd5d3BFaVZKSU51
      NXRuRlJRNFRYRUxNR2g1Y3ZMTEpJaWsKLS0tIHBGTWRUQjh6bGc4WWJDbThOM1FJ
      ZUFYeWc0a1pXUXliLy9IN3E4czFmWWsKa5YmXKdvYuW9Dm/z9KE+SCvjXZYzq+Up
      naqZkJUsz/p4wjD/jvBYADdyFf76HD7yPXU18ulbwq9gTU3SaK2PzQ==
      -----END AGE ENCRYPTED FILE-----
    '';
    # Configure Docker.
    # TODO: figure out how to get this config living closer to the
    # installation of docker itself.
    age.rooter.derivedSecrets."/home/${config.snow.user.name}/.docker/config.json" = {
      user = config.snow.user.name;
      group = "users";
      mode = "0400";
      script =
        let
          docker-config-template = pkgs.writeText "docker-config-template" (builtins.toJSON {
            "credHelpers" = {
              "900965112463.dkr.ecr.us-west-2.amazonaws.com" = "ecr-login";
            };
            "auths" = {
              "containers.snow.jflei.com" = {
                "auth" = "@auth_placeholder@";
              };
            };
            "detachKeys" = "ctrl-^,q";
          });
          gen-docker-conf = pkgs.writeShellApplication {
            name = "gen-docker-conf";
            runtimeInputs = with pkgs; [ gnused ];
            text = ''
              sed "s/@auth_placeholder@/$(cat ${config.age.secrets.snow-containers-auth.path})/" ${docker-config-template}
            '';
          };
        in
        "${gen-docker-conf}/bin/gen-docker-conf";
    };

    # We need to install openvpn3 explicitly because NetworkManager-openvpn only
    # has support for openvpn2. See
    # https://gitlab.gnome.org/GNOME/NetworkManager-openvpn/-/issues/69.
    programs.openvpn3.enable = true;
    # With systemd-resolved running, openvpn3 won't stomp on /etc/resolv.conf.
    services.resolved.enable = true;

    # Set up a local DNS server
    services.dnsmasq = {
      enable = true;
      # Configure the system to actually *use* dnsmasq (in this case, this
      # updates systemd-resolved to use 127.0.0.1 as a DNS resolver).
      resolveLocalQueries = true;
      settings = {
        # Only let dnsmasq bind on the loopback interface. This prevents a port
        # conflict with systemd-resolved.
        interface = "lo";
        bind-interfaces = true;

        address = [
          "/local.honor/127.0.0.1"
          # See notes above about `virtualisation.docker.daemon.settings.dns` to
          # understand why this is necessary.
          "/host.docker.internal/172.17.0.1"
        ];
      };
    };

    # Set up ssh agent
    programs.ssh = {
      startAgent = true;
      enableAskPassword = true;
      askPassword = "${mfa}/bin/mfa-askpass";
      extraConfig = ''
        AddKeysToAgent yes
      '';
    };
    environment.variables.SSH_ASKPASS_REQUIRE = "prefer";

    # Enable gpg agent
    programs.gnupg.agent.enable = true;
    environment.etc."gnupg/gpg-agent.conf".text =
      let cfg = config.programs.gnupg;
      in
      ''
        # Reconfigure gpg-agent to have a longer lived cache: up to 8 hours after
        # last used, but the cache also expires when it is 8 hours old, even if it
        # has been used recently.
        default-cache-ttl ${toString (12 * 3600)}
        max-cache-ttl ${toString (12 * 3600)}
      '';

    # QEMU emulation used for compiling for other architectures.
    boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

    # Needed by ~/bin/allprocs
    programs.sysdig.enable = true;

    # See my-aws-vault for details.
    age.secrets.aws-vault-file-passphrase = {
      rooterEncrypted = ''
        -----BEGIN AGE ENCRYPTED FILE-----
        YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBYOE5Yd1hjTisvcDRzVTJ2
        REFjSkZoYWRJOGVxa3ZTdTV1MnQ2YWNjNzIwCmIrVWpINWFrN01reXZ6Z0NtZC94
        Z2JUVHJtaDJIRlQ4cHRuK1FleWF1ZGsKLS0tIFZVWUZlWE9ac2JuUVl1R20xMCt0
        ZHBFeXphVVJUT090U0l3TC9LOVVEUmMKApEd7chMuK9kB2fCOscPI16vjlwPyA7V
        rC77LyauPwyX47G+00wJ2qCerKxSzjf1/WjCWg==
        -----END AGE ENCRYPTED FILE-----
      '';
      owner = config.snow.user.name;
      group = "users";
    };

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
      binutils

      ### Honor
      mfa
      my-aws-vault
      (lib.mkIf config.snow.enable-h4 h4-cli)
      # server-config
      (vagrant.override {
        # I'm having trouble installing the vagrant-aws plugins with this setting enabled.
        withLibvirt = false;
      })
      gnupg
      openssl
      aws-sam-cli
      # dev setup scripts
      amazon-ecr-credential-helper
      # external-web
      nginx
      # kube-config (and others)
      gnumake
    ];
  };
}
