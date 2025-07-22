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
    };
  };

  config = {
    networking.domain = config.snow.tld;

    clan.core = {
      settings.state-version.enable = true;
      networking = {
        # Ideally this would be just `localhost`, and not require ssh to
        # be enabled on the build machine. See
        # https://git.clan.lol/clan/clan-core/issues/3556.
        buildHost = "jfly@localhost";
        targetHost = "jfly@${config.networking.fqdn}";
      };
    };

    # Ensure that commands like `nix repl` and `nix-shell` have access to the
    # same nixpkgs we use to install everything else.
    nix.nixPath = [ "nixpkgs=${pkgs.path}" ];

    nix.package = pkgs.nixVersions.latest;

    environment.systemPackages = with pkgs; [
      config.snow.neovim.package
      wget
      curl
      tmux
    ];

    programs.mosh.enable = true;

    environment.variables = {
      EDITOR = "vim";
    };

    users.groups.media.gid = 1002;
    users.groups.bay.gid = 1003;

    # Flakes!
    nix.settings.experimental-features = [
      "recursive-nix"
      "nix-command"
      "flakes"
    ];

    nix.settings.extra-system-features = [
      "recursive-nix"
    ];

    # I18N stuff
    i18n.defaultLocale = "en_US.UTF-8";
    services.xserver.xkb.layout = "us";

    # Disable ssh password auth. I'm a little surprised that this isn't the default.
    # Note that we don't enable openssh itself, that's for individual machines
    # to decide.
    services.openssh.settings.PasswordAuthentication = false;

    # Enable deployments by non-root user.
    nix.settings.trusted-users = [ "@wheel" ];
    security.sudo.wheelNeedsPassword = false;

    # Enable ssh for all machines.
    services.openssh.enable = true;

    users.users.jfly = {
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "media"
      ];
      openssh.authorizedKeys.keys = [ identities.jfly ];
    };

    users.users.rachel = {
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "media"
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
  };
}
