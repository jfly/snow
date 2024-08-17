{ config, pkgs, lib, ... }:

let
  inherit (pkgs.snow)
    mfa
    ;
in
{
  options = {
    snow = {
    };
  };

  config = {
    # esp32/watchy tinkering
    services.udev.packages = with pkgs; [
      platformio-core.udev
    ];

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
      # `/etc/hosts` is not good enough, as some stuff like nginx actually ignores
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

    # I probably don't need this anymore. It was useful back when I used
    # openvpn3, to keep it from stomping on /etc/resolv.conf.
    services.resolved.enable = true;

    # Set up a local DNS server
    services.dnsmasq = {
      enable = true;
      # Configure the system to actually *use* dnsmasq (in this case, this
      # updates systemd-resolved to use 127.0.0.1 as a DNS resolver).
      resolveLocalQueries = true;
      settings = {
        # Bind on all interfaces as they come and go. This is important for
        # docker, as the docker0 interface appears at some point asynchronously
        # when booting up.
        # It's important for dnsmasq to bind on specific interfaces, because
        # otherwise it will try to bind to a wildcard address, which conflicts
        # with the 127.0.0.54 that sytsemd-resolved listens on.
        bind-dynamic = true;

        address = [
          # See notes above about `virtualisation.docker.daemon.settings.dns` to
          # understand why this is necessary.
          "/host.docker.internal/172.17.0.1"
        ];
      };
    };

    # Set up ssh agent
    programs.ssh = {
      startAgent = true;
      extraConfig = ''
        AddKeysToAgent yes
      '';
    };
    environment.variables.SSH_ASKPASS_REQUIRE = "prefer";

    # Enable gpg agent
    programs.gnupg.agent = {
      enable = true;
      settings = {
        # Reconfigure gpg-agent to have a longer lived cache: up to 8 hours after
        # last used, but the cache also expires when it is 8 hours old, even if it
        # has been used recently.
        default-cache-ttl = toString (12 * 3600);
        max-cache-ttl = toString (12 * 3600);
      };
    };

    # QEMU emulation used for compiling for other architectures.
    boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

    # Needed by ~/bin/allprocs
    #<<< programs.sysdig.enable = true;

    environment.systemPackages = with pkgs; [
      ### Version control
      git
      git-filter-repo
      # `gh` manages credentials internally, but it also honors the
      # `GITHUB_TOKEN` env var if one is present. However, this interferes with
      # development in repos where I *do* have a `GITHUB_TOKEN` env var set.
      # Since I seem to rely upon `gh`s internal authentication anyways, we can
      # just completely ignore external `GITHUB_TOKEN` environment variables.
      (pkgs.symlinkJoin {
        name = pkgs.gh.name;
        paths = [ pkgs.gh ];
        buildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/gh --unset GITHUB_TOKEN
        '';
      })

      ### Network
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
      strace
      xxd
      rsync
      snow.mycli
      miller
      jq
      mfa

      ### editor
      snow.neovim
      # TODO: don't install these globally, instead just make them available
      # to neovim.
      pyright
      nodePackages.typescript-language-server
      shellcheck # (used by neovim?)
      shfmt
      (ruff-lsp.overridePythonAttrs (old: rec {
        # ruff-lsp automatically falls back to some version of ruff (see
        # https://github.com/jfly/nixpkgs/blob/5e5319a2b01f4aa39dc99a7d7a1b70bacfe60f24/pkgs/development/tools/language-servers/ruff-lsp/default.nix#L57-L58).
        # I don't want that, because I only want ruff autoformatting to occur
        # in projects that actually use ruff. So, we override ruff-lsp's
        # makeWrapperArgs to not include `ruff` itself.
        makeWrapperArgs = [
          "--unset PYTHONPATH"
        ];
      })) # (used by neovim)
    ];
  };
}
