{ config, pkgs, ... }:

let identities = import ../shared/identities.nix;
in
{
  # Enable colmena deployments by non-root user.
  deployment.targetUser = "kent";
  nix.settings.trusted-users = [ "root" "@wheel" ];
  security.sudo.wheelNeedsPassword = false;

  # Set up users + ssh.
  services.openssh.enable = true;
  users = {
    mutableUsers = false;
    users.root = {
      hashedPassword = "$y$j9T$t3BpX5kVjiPQVbo62fAfY.$qoUQpc5SJTyLdrQFYdMfIaJ8GWE7owrDUl7FknHYv.8";
    };
    users.kent = {
      isNormalUser = true;
      openssh.authorizedKeys.keys = [
        identities.jfly
      ];
      hashedPassword = "$y$j9T$1MtdJyQqs.RBtk5w3iv3h0$taL.rhRXTuiogWXtFYq3tSPcdt5JgMCcjakljOh5ZA9";
      extraGroups = [ "wheel" ];
    };
  };
}
