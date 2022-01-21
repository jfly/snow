{ pkgs, ... }:

{
  image = "wallabag/wallabag:2.4.2";
  environment = {
    POSTGRES_USER = "wallabag";
    POSTGRES_PASSWORD = pkgs.deage.string ''
      -----BEGIN AGE ENCRYPTED FILE-----
      YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBsZktsMUF2STRnUXdYNjlE
      OWJiWVRHazJEeHpUWEVaTDV3bDd5L21ndWdVCnZmZExDR0pMNFBJM0Jxb29EVUs0
      YldkY0F0eDJGZHdBelZwZ1o2S3FWY1EKLS0tIHNpRVM1d2UxVWZ3bm1IcnpRbmJZ
      WDNqRzB5aVdsY2pSUm8zK2tHMlpOU28KjfTZzv8jBPM5NzaKgwRUywso4aPvYJhZ
      evNLRn765Hk4v4va2ATcChpLOoOq4dbMtordjQ==
      -----END AGE ENCRYPTED FILE-----
    '';
    SYMFONY__ENV__DATABASE_DRIVER = "pdo_pgsql";
    SYMFONY__ENV__DATABASE_HOST = "clark";
    SYMFONY__ENV__DATABASE_PORT = "5432";
    SYMFONY__ENV__DATABASE_NAME = "wallabag";
    SYMFONY__ENV__DATABASE_USER = "wallabag";
    SYMFONY__ENV__DATABASE_PASSWORD = pkgs.deage.string ''
      -----BEGIN AGE ENCRYPTED FILE-----
      YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBsZktsMUF2STRnUXdYNjlE
      OWJiWVRHazJEeHpUWEVaTDV3bDd5L21ndWdVCnZmZExDR0pMNFBJM0Jxb29EVUs0
      YldkY0F0eDJGZHdBelZwZ1o2S3FWY1EKLS0tIHNpRVM1d2UxVWZ3bm1IcnpRbmJZ
      WDNqRzB5aVdsY2pSUm8zK2tHMlpOU28KjfTZzv8jBPM5NzaKgwRUywso4aPvYJhZ
      evNLRn765Hk4v4va2ATcChpLOoOq4dbMtordjQ==
      -----END AGE ENCRYPTED FILE-----
    '';
    SYMFONY__ENV__DOMAIN_NAME = "https://wallabag.clark.snowdon.jflei.com";
  };
  extraOptions = [
    "--network=clark"
  ];
}
