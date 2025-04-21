{
  inputs,
  config,
  pkgs,
  ...
}:

{
  imports = [
    inputs.simple-nixos-mailserver.nixosModule
    ./postsrsd.nix
  ];

  mailserver = {
    enable = true;
    certificateScheme = "acme-nginx";

    # Keep in sync with `iac/pulumi/app/dns.py`
    fqdn = "mail.playground.jflei.com";
    domains = [ "playground.jflei.com" ];

    loginAccounts = {
      "jfly@playground.jflei.com".hashedPasswordFile = config.age.secrets.mail-jfly.path;
      "jeremy@playground.jflei.com".hashedPasswordFile = config.age.secrets.mail-jeremy.path;
    };

    dkimPrivateKeyFiles = {
      "playground.jflei.com" = config.age.secrets."playground.jflei.com.mail.key".path;
    };
  };

  services.postfix.config.virtual_alias_maps = [
    # Extending https://github.com/NixOS/nixpkgs/blob/a9fe4d6d8ccde780e872ed1446f3746498152663/nixos/modules/services/mail/postfix.nix#L833C87-L833C108
    "hash:/etc/postfix/virtual-jfly-test"
  ];

  services.postfix.mapFiles.virtual-jfly-test = pkgs.writeText "postfix-virtual-jfly" ''
    me@playground.jflei.com jfly@playground.jflei.com, jeremyfleischman+subscriber@gmail.com
  '';

  security.acme.acceptTerms = true;
  security.acme.defaults.email = "jeremyfleischman@gmail.com";

  age.secrets.mail-jfly = {
    # ```
    # nix run nixpkgs#mkpasswd -- -m bcrypt | python -m tools.encrypt
    # ```
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
  age.secrets.mail-jeremy = {
    # ```
    # nix run nixpkgs#mkpasswd -- -m bcrypt | python -m tools.encrypt
    # ```
    rooterEncrypted = ''
      -----BEGIN AGE ENCRYPTED FILE-----
      YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBROU5GK2lZWHg0aDM0eWZK
      TEl5cXZISTliTHd1L1cyRWJWL0ZXUDRwUG53CjFrK0tYQlRVajZsVjk3c0JZV3FP
      dnoxM0g3TXZXUXpETnc0YlhienBaVkUKLS0tIG1EcEQvSUZGeUJPR2tEZnJvdmNF
      c3pzSWhOYUNaVFp1dzJBM24yeGl4RTAKOCZOtl3GOKPywD027MGDjXc2ORTWj7wI
      wt0sUQJb7AjcZ3ZI/UWJk8JXkEPoyipTcCk8iNF73JZEQwhZl4G/D/f4sCk/0vjG
      mY5STdExe4ws6T0qIHAxFT93OnM=
      -----END AGE ENCRYPTED FILE-----
    '';
  };

  age.secrets."playground.jflei.com.mail.key" = {
    owner = config.services.opendkim.user;
    group = config.services.opendkim.group;
    rooterEncrypted = ''
      -----BEGIN AGE ENCRYPTED FILE-----
      YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBPTTE4UEVWMk8vQnhLMW9y
      UE5IcHhNa1R6SkRNYUROUWpWL0J6K0tEUXljClIxZUx3NG4wby8zbzdJZlUwL3Zr
      bjBYN3JmVVVJalNsWXZ1NzFIZ2ZkVk0KLS0tIHJ3c3Q2eHFSL25tOFo1ckNZRDVx
      b215YlJmZ1BTRmpKbGtEMEhzUDBwVWcKiLP4jLsLLwfBIDxhzhZwYmq5Nc3L0C+d
      mLyM2CoEJ/Vwp9NHim9x9N7G3BtINcqUAxdchKhXjlutSruWIYAKzoL6vcFg8imK
      OVCcqQiNtlH551aifJdGdqJPgqMjMznqs9rnGQKzjlj9nPpcpBzNh174huk1JLxq
      7Qnd2QMKh5mFqFQ/dj+zdEMh9NfVhlI5jNFIHoq1jASXMaALFYa4EU2jvGmT/u2j
      4icK4devRJmub9+vF9HYqUFW0WMW6KGtoe1q+xpRfmSy70L6Uo5/iADVnBTPoQBz
      n74aPpQhvncYJmY82QSP2GIZQWxjxE0hux9mTjYDUQr8lzfpBJZJOgHlK3Nwg9Vq
      SbG/IQRZGsGaXk0X2wE8ZMeW8h2ZEQfKz7xTI0aY6kda5N/+jnd0pGnljSd7qTGr
      1RiqzOg8U6J1ZRqrORBJuwDpn2buRp+182wj6+Ed39bEjfYVBwUJpsm0XiQtFDTN
      6zvuSUZZ7x6yLkbKwaGRTPAhNaSaVmJNgZpQ3PBk9FU6azbCqZu93GYUp8qot413
      YpSucefNvXikY0CtyczBV6ruBg/GkkhWFARkSxXgixXTnjXozpk43vFaMRXaP/uF
      cEdic50IqCn3y7/lmjs14JW3DctyZzAbnIMqEH/b8iySeqwzDYl62OG8z3ckxbHZ
      nSJoldvoz4s90vsH0+ZnrWw78xBZfHpWQfhRBOinBNsItccRefrrw+MDOma5c7aH
      o+O5kmAl+L74A2IU2t42I92shIAjyTONM4aprwi86FG1dhncADXIPVu735yfjdNT
      aRPMePHwvD4rysIiT7/P8DTJ8Rt6pVXROlZocpe0bKj8npGE1txfYvbHICnkLc9u
      +R9FTGABMbzEcaMsA6cpa45w4/WjABIz0HVFydJtsixSUo5jlDg9Qdg42PbPJZep
      NjyyQDkRw0nWQg6iDqFXVnTd7xK4Z8ir0iD17jz6SH/3RWlAAP2OJhmDfyR6vZOi
      Jtrbezni8z7k93s/KsMc3FUMQnSLURbkHIhH9J+9lUfsYpwuk2Qm05kDo4O/cobg
      TQYtJMB4iL/GfXePr5CP70E+BOcEVZK1jvw1oz1Ld7Q7nJS169ASa32StAqA2/8Z
      G3n3I66VBCG9IyUxFFCiZZtKLqew17g7RS7bSjQsi2RVz/R+IqV3DzxIaBkW0ijQ
      dUCYYIjHxPCRjTeotj9+zgQtAeyIfX9boDYo7ZLDAxLCPg8Uwtbdjazqw9tVGCto
      XpucO1sqfXFNTOVf
      -----END AGE ENCRYPTED FILE-----
    '';
  };
}
