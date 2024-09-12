{ config, ... }:

{
  imports = [
    # TODO: accesss in a less weird way, perhaps as module args threaded in via
    # `specialArgs`? See
    # https://github.com/BirdeeHub/birdeeSystems/blob/8e5538d66690234f5bccd1c2a9211858b933e466/flake.nix#L304
    # for one such example.
    ../../../modules/kodi-colusita
  ];

  services.kodi-colusita = {
    enable = true;
    sshIdentityPath = config.age.secrets.colusita-media-identity.path;
  };

  age.secrets.colusita-media-identity = {
    # pattern.kodi
    rooterEncrypted = ''
      -----BEGIN AGE ENCRYPTED FILE-----
      YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBBSFZKV1FuZDJlOHpvTnJY
      NWJTN1lmRTV3NWgzaUJza3k3Q1hMa1RrcW4wCjR5OWs5dG43ckg5T01DWlQ4MUQy
      NlNsdzY2NVViY0duQVVpSjZBWTdXNEEKLS0tIEN3TkhmcGxTc0FRMjdHdUdBMUUy
      UTlXSmZoNzBhVXEyQy9DNm9xa2FSSUUKrstFf9sOCwfLUVPJiuCNFgAUHcikczbI
      3surfNxHLDhVcsy07oU+twa3QREBDoatlsTjfVIrzPUlV3Nk6uEz4oVyKwhEsQka
      F/b3E3bymJcG6Do1JoHFl92QyCW5jiVXviaq6Q/J+4LGjsr5w8oXktfU7mwymuBx
      Ww3BjMYWy8hkyk7L6s+k7h3r48U2MCfWAXKmHAaPvhBf+lWZbsNeMlRO7F+eaR3/
      4OVSoRmIOSZnFJwcmww47LMHR+aYU+XfYaBa234hzDqd06heIwZNSKChHKzZDSZh
      D1TFF8gVyCgfU8O+kxtOpcsthK43s8LbgwW0Bql8i/mOCsyVwCHyFH5MTCqtmb17
      PbktMWjHwYOf+jnIZXnmTurvQY5QizQNTKLwirbKE8K3YXZtFBV/pAtyUrS0Irvz
      dbgILIefyBBGxj/1DMz7FQ2NhswAar8YXBya3/b0C622GIh+179NI7vc4zbnfpjP
      QyJy8OPyrqERaCEfbP2H9pf7lEwR1mtVP3dDibd2EQsLjB5AK+qefKccqFOH9Z0G
      c0GxMzZuUOh+6gJPpM7iPYJrXM5shwUxhsgS1ftOkS8Mt47nulN2G/4Hxw==
      -----END AGE ENCRYPTED FILE-----
    '';
  };
}
