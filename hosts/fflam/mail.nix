{
  inputs,
  config,
  pkgs,
  ...
}:

let
  arc.selector = "arc-2025";
in
{
  imports = [
    inputs.simple-nixos-mailserver.nixosModule
    # <<< ./postsrsd.nix
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

    dkimDomainPrivateKeyFiles = {
      "playground.jflei.com" = config.age.secrets."playground.jflei.com.mail.key".path;
    };
  };

  services.postfix.config.virtual_alias_maps = [
    # Extending https://github.com/NixOS/nixpkgs/blob/a9fe4d6d8ccde780e872ed1446f3746498152663/nixos/modules/services/mail/postfix.nix#L833C87-L833C108
    "hash:/etc/postfix/virtual-jfly-test"
  ];

  services.rspamd = {
    #<<< path hack? >>>
    overrides."arc.conf".text = ''
      domain {
        playground.jflei.com {
          path = "/var/lib/rspamd/arc/playground.jflei.com.org.arc-2025.key";
          selector = "${arc.selector}";
        }
      }
    '';
  };

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
    owner = config.services.rspamd.user;
    group = config.services.rspamd.group;
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

  age.secrets."playground.jflei.com.org.${arc.selector}.key" = {
    owner = config.services.rspamd.user;
    group = config.services.rspamd.group;
    path = "/var/lib/rspamd/arc/playground.jflei.com.org.${arc.selector}.key";
    symlink = false; # <<< symlink has wrong user/group?: https://github.com/ryantm/agenix/issues/261 >>>
    # ```
    # nix shell nixpkgs#rspamd --command rspamadm dkim_keygen --selector arc-2025 --domain playground.jflei.com --type rsa --bits 2048 --priv-output pem --privkey arc.key -o dns
    # python -m tools.encrypt < arc.key
    # ```
    # And finally, update DNS accordingly (the output of `rspamadm` will include the relevant DNS TXT record).
    rooterEncrypted = ''
      -----BEGIN AGE ENCRYPTED FILE-----
      YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBMZnB0WEtPVmtFQzdsbnJT
      WWxEdUI5TWg1UVZOSXJMTFdNU3FEVnNFbkZNCkhBUkpGNnlEcytEVXNnMXBsRSta
      dWgvdmo1SGMrYW5Xb3JLbHl4c2Zka2sKLS0tIEwrakRzWHNyeFBuTkxXMzBMTUNi
      L1RKNlNWR0lFZlYrVFVxWCtvY0lTeUEKY7YyMKqFxD18wq/66X6iUHLOte7L45aS
      dhshNcZ9P1Tf9yAd5R5Sg1Fox48jF9PSADgnrGvCjXsnWoi8Ruq1pmVx1DPmU9VM
      MXvXcxnHtbyX9iSOpdZtisbiRNBSyDvH2GzY0KNV9IyqEaoIznCee/76WHM7grHU
      ihV36lzk/gLJSkhJFdVXMKAKsCUo2NmF1XHTYtKz3Jf03hmX5xVed/xNR5R2pOwA
      yE8oPlbxokCnx9ubgV+ZwI+AyeyJb8lFO/ltfRS78y1UCeHYHuHaTmN/qASCZVVq
      v/Jd8H2t7wbgk74hB/GVSj5mGW/YOsIF0mbRMLjoJ1WjV0gWASqCpsbMKxJ3RytT
      2if4Z4gv1YH+QoeAmiuHaMVcbzq+IYYxwXYjsMtuPXUQ/YdJj/udzDaD475v80eW
      ogPYZj1MnWR5q5WUsM6kVDZOK2UQBotVFu4CsWNsMh0l/x+9jyALf3cM1qE8PZaG
      UhcoQZsJENj/6fdZRwuf8zk1lv2yuh8v8qi1x6AclP+RVRc3QNuC5cpdQEoyuqhE
      GGBtGvZn8MwysfVTpiQaxGs4uc5PrboE/GrQiCLy5ofs+mNBKsHMByGNfzODQXPy
      sFJG7ervx4P/bTqJZa2+JgXCTAdIizDdJqzudxE5SDrgkacJIHpOpbUaZPodZl43
      ESjhNvp/EwxBGyad4Y9iwWz7TbO+qIHybM2OPWDOxtBRBbXojDoQImdvJsJmwZs4
      +BrPeYJie8UJuI+Vi51VK+f9ZIuwR1at2YutocXjHJwI4LSIqe++RGMjlUpMA/5K
      b+460hw/SqOJhWGRXo5qka/g8gPu+FMXl0+XCS3dlfrkyMUKXzSoPNXqu6YiSMla
      sEdcZNUoda5dEa2X7G7q/z+wwucUOzgezBTWznUWKG19mhmExit8tb0NT+IzUs3v
      qgdkYheP6atfIO5M2JboexB6oneAj9IHf88uVPf6SMwGg/Sy5yuCacmJU3mIAmCz
      GYOB9ifQ4HkAGm3G1lKB/nwlfil6bJ3UeKNwD34a0xnUNWrBy9vyNemko03RJyNr
      4qQvM2cfEckb6scZe/XUtIA+AwYQqktJtSdqDXa9KHBTekevsX9IpOGPNO63QE5Z
      JqwojxEHpSjTKsaAkN4ksMcpgkCTHY6OJI+mKyou8fIXkrX1Xw6Ak/lZjc2KAOkp
      4RstioJPKX5iizVzAiaiQOa6svcks1fRWM9NkGrDtySpt8r2ajALCco1kHGG0wok
      9cYlBqjKYgASfPcrBnauwaw/0w6+68JbGSXR57WwfRWiq7TyqWlK+x1vmK4vp9RD
      YA8I8ne3cu9pLDMmG0MKZ3lY1vowA3eGqE0QNmoW77EQrOEliYgqICV0crmAghX9
      UE4K3vGC3jhnFDYIAgplWoeRuGdMMatY2CmX6Im3VSVFURsDfnWowgkc+lEa2QbT
      84VmtR5V68cEawJI6MJb4YbfI8PWQOMxTRbChSv1EgE9n8JE/5+iWV14YuzAq9WF
      iugFsSyWk12oLpvriMf20CHNW23fAyNyfs+XHC3csAbCEmZK46Gv7dhSiTK+j1ah
      bImOfzhndbIkVp4iujSrOMHJv0gReR++ggN8ToG7ZYt5ymkUw6jVtrVlQsTOZige
      9hskCzMBYMFB9SS5QYhUISpF24evP+dwPgfqZnlvzKKbVE7Y3GUBB3n7ZlifiRus
      xStFCfNhi0PufeEOxU/fB1UzOtUs2xHBbIuSoaobnIL4GIZZJXmE2oyHWIrSMOyl
      LIfWDMOykilbbprS1JIT4zeFVsrjHCB4MoQyyWOsbvl2o8L4np7K/SC4yx+yxjVw
      Het18aW3exdF+yJkZOPdJxsHrEz0lp4tLJGVf4Co/XdtbbE0SYMyzA0C10mK+iA6
      7dnKh2ecnPO91/Khopvg51YyjP+K5aIqUu4kEJB+CX3JEPa9xNXlObCEDveKAOZq
      WNyzOLdf0no6FzmedQWBMVu4sZ+DisvvNAksoIFwck0ScaVcSwZF1vLqgBHGgGEu
      DXgYgVHDYw5koX6Pq+9NjFP2Air9THaV+3nSt8ua/j0zHDOf/t+JoNFxJ27DupD4
      r7FzxIzSd9bFCNX1E++6WDb764G+072shp2sg8mEyoSiUdJ5ageqRYqSyO+oynyk
      hQikCKeLWdCVNIo0iex/6Fne3/ZiMgr8/pcr+nI3xmogmQhMffzC8AxvxiaFKbvp
      H0AY4RMjQnHmZpw7wPZwRQNIdHJt62/krVoaEVD0dpRnFwuSNIqYITVNWnAZCrXo
      TDOPc/UxVB/XFCCfKqR4e7YU5sklWGhru91ugIVanA==
      -----END AGE ENCRYPTED FILE-----
    '';
  };
}
