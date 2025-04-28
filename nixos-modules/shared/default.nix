{
  lib,
  flake',
  flake,
  config,
  inputs,
  pkgs,
  clan-core,
  ...
}:

let
  legacyNonClan = clan-core == null;
  identities = flake.lib.identities;
in
{
  imports =
    (
      if legacyNonClan then
        [
          inputs.agenix.nixosModules.default
          inputs.agenix-rooter.nixosModules.default
        ]
      else
        [
          inputs.clan-core.clanModules.state-version
        ]
    )
    ++ [
      flake.nixosModules.nix-index
    ];

  options = {
    snow.neovim.package = lib.mkPackageOption {
      neovim-lite = flake'.packages.neovim.override { full = false; };
    } "neovim-lite" { };
  };

  config =
    {
      # Ensure that commands like `nix repl` and `nix-shell` have access to the
      # same nixpkgs we use to install everything else.
      nix.nixPath = [ "nixpkgs=${pkgs.path}" ];

      # Use latest nix. There are apparently issues with it [0] [1], but I want
      # to see if they affect me personally.
      # Furthermore, the newer version contains one fix [2] I do care about.
      # [0]: https://github.com/NixOS/nixpkgs/pull/315858
      # [1]: https://github.com/NixOS/nixpkgs/pull/315262
      # [2]: https://github.com/NixOS/nix/pull/9930
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

      users.users.jfly = {
        isNormalUser = true;
        extraGroups = [
          "wheel"
          "media"
        ];
        openssh.authorizedKeys.keys = [ identities.jfly ];
      };

      # Enable ssh for non-roaming machines.
      services.openssh.enable = lib.mkDefault (config.networking.domain != null);

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
    }
    // (
      if legacyNonClan then
        {
          age.rooter.generatedForHostDir = lib.mkIf legacyNonClan ../../secrets;
        }
      else
        { }
    );
}
