{ inputs, config, ... }:

{
  imports = [
    inputs.simple-nixos-mailserver.nixosModule
  ];

  mailserver = {
    enable = true;
    certificateScheme = "acme-nginx";

    # Keep in sync with iac/pulumi/app/dns.py
    fqdn = "mail.playground.jflei.com";
    domains = [ "playground.jflei.com" ];

    loginAccounts = {
      "jfly@playground.jflei.com".hashedPasswordFile = config.age.secrets.mail-jfly.path;
    };
  };

  security.acme.acceptTerms = true;
  security.acme.defaults.email = "jeremyfleischman@gmail.com";

  age.secrets.mail-jfly = {
    # nix run nixpkgs#mkpasswd -- -m bcrypt | python -m tools.encrypt
    rooterEncrypted = ''
      -----BEGIN AGE ENCRYPTED FILE-----
      YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSArM2dYQ2M0elcreWtJbmFh
      aTBLYXVMYy9vaTY3cUhNWkQ5M3liZFBVbXdJCkxGZ2RHSEhNVll3N3U4SytBNmhj
      UXRubEQ0VkpLdWpjWWYvVGk0TWZ0ZGsKLS0tIHNyaG1rTjkzNGZQeGNMdm5iWVpY
      ZzdpZEdXeXNYTW1qTE5DV0VxR0pFakkK0suG6kluCm5bKU2cuh0coi2Z95zmuvXs
      H/sUL+gqBNFs4jZ4rE6m+OP6i03Aw8IIGt4w7nyfHu7fxtNgDzdfRCLP8GprXdIi
      tfM1IreQ/f5dDkyvfgLwDTbwc/E=
      -----END AGE ENCRYPTED FILE-----
    '';
  };
}
