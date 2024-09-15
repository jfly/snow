{ flake, ... }:

let identities = flake.lib.identities;
in
{
  # Enable deployments by non-root user.
  nix.settings.trusted-users = [ "root" "@wheel" ];
  security.sudo.wheelNeedsPassword = false;

  # Set up users + ssh.
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };
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
      extraGroups = [
        "wheel"
        "media" # access to /mnt/nexus
      ];
    };
  };
}
