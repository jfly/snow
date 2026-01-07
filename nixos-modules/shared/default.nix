{
  lib,
  flake',
  flake,
  config,
  pkgs,
  ...
}:

let
  identities = flake.lib.identities;
in
{
  imports = [
    flake.nixosModules.nix-index
    flake.nixosModules.step-ca
    flake.nixosModules.backup
    flake.nixosModules.monitoring
    flake.nixosModules.nginx
    ./services.nix
  ];

  options = {
    snow = {
      neovim.package = lib.mkPackageOption {
        neovim-lite = flake'.packages.neovim.override { full = false; };
      } "neovim-lite" { };

      tld = lib.mkOption {
        type = lib.types.str;
        description = "TLD for services hosted on the overlay network";
        default = "m";
        readOnly = true;
      };

      subnets = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.submodule {
            options = {
              ipv4 = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
              };
              ipv6 = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
              };
              interface = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
              };
            };
          }
        );
        readOnly = true;
        default = {
          # Ideally we'd share this with our router configurations.
          colusa-trusted.ipv4 = "192.168.28.0/24";
          colusa-iot.ipv4 = "192.168.29.0/24";
          colusa-guest.ipv4 = "192.168.30.0/24";

          nixos-containers = {
            ipv4 = "172.20.0.0/24";
            ipv6 = "fda0:f78f:a59e:20::/64";
          };

          overlay = {
            ipv6 = config.clan.core.networking.zerotier.subnet;
            # This interface name is determined from the network id, but we
            # don't have eval-time access to it. So, you have to first deploy
            # the Zerotier network, and *then* fill this in. This could be
            # done in one shot if everything that needed this supported
            # Linux's interface altnames. See
            # https://git.clan.lol/clan/data-mesher/issues/222.
            interface = "zthjzvlscg";
          };
        };
      };
    };
  };

  config = {
    networking.domain = config.snow.tld;

    clan.core = {
      settings.state-version.enable = true;
    };

    snow.services.${config.networking.hostName}.nginxExtraConfig = ''
      add_header Content-Type text/plain;
      return 200 "Welcome to ${config.snow.services.${config.networking.hostName}.fqdn}!";
    '';

    # Ensure that commands like `nix repl` and `nix-shell` have access to the
    # same nixpkgs we use to install everything else.
    nix.nixPath = [ "nixpkgs=${pkgs.path}" ];

    nix.package = pkgs.nixVersions.latest;

    environment.systemPackages = with pkgs; [
      config.snow.neovim.package
      wget
      curl
      tmux
      tree
      psmisc # Provides `pstree`.
    ];

    programs.mosh.enable = true;

    environment.variables = {
      EDITOR = "vim";
    };

    users.groups.media.gid = 1002;
    users.groups.bay.gid = 1003;

    nix.settings.experimental-features = [
      "recursive-nix"
      "auto-allocate-uids"
      "cgroups"
      # Flakes!
      "nix-command"
      "flakes"
    ];

    nix.settings.extra-system-features = [
      "recursive-nix"
      "uid-range"
      "cgroups"
    ];

    nix.settings.auto-allocate-uids = true;

    # I18N stuff
    i18n.defaultLocale = "en_US.UTF-8";
    services.xserver.xkb.layout = "us";

    # Enable deployments by non-root user.
    nix.settings.trusted-users = [ "@wheel" ];
    security.sudo.wheelNeedsPassword = lib.mkDefault false;

    # Enable ssh for all machines.
    services.openssh = {
      enable = true;
      # Disable ssh password auth. I'm a little surprised that this isn't the default.
      settings.PasswordAuthentication = false;
    };

    users.users.jfly = {
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "media"
        "bay"
      ];
      openssh.authorizedKeys.keys = [ identities.jfly ];
    };

    users.users.rachel = {
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "media"
        "bay"
      ];
      openssh.authorizedKeys.keys = [ identities.rachel ];
    };

    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };

    # Disable nix channels. Use flakes instead.
    nix.channel.enable = false;

    snow.step-ca.role = lib.mkDefault "client";

    # Workaround for avahi crash on name conflicts:
    # <https://github.com/avahi/avahi/issues/117#issuecomment-401225716>
    # Endless logs like "Host name conflict, retrying with ..."
    services.avahi.allowInterfaces = [ config.snow.subnets.overlay.interface ];
  };
}
