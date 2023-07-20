{ config, lib, pkgs, ... }:

{
  home-manager.useGlobalPkgs = true;
  home-manager.users.${config.snow.user.name} = (import ../shared/home.nix {
    inherit config;
  });


  age.secrets.wallabag-jfly-client-id = {
    owner = "jeremy";
    rooterEncrypted = ''
      -----BEGIN AGE ENCRYPTED FILE-----
      YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSAwaThYNXlOK213eG1CWXJo
      L3lmY2FubFpZNSt5TjRNTHliOVIyd3JRNWpRClVjaEFId3pCZ0x6dUpNM0tNbVdC
      N3V0enFhSm1PdzB1TzYxeE41K29DbjAKLS0tIDZvSUhyeFpOMlE3UnVTa2RXSEQx
      VUMxejBvMG4yczRuMjNmbHZXMG1uc00K8cRL8BXiKSfxNW/hA7FGHfI1NOr+kake
      1dD0jivvNdvaLKAqSYzNNGn3AQf8Rog5zHFsDJ/tZ4KoDNg1U0A5YxcRhGT1XG2A
      57CSkBLsqJXXec0=
      -----END AGE ENCRYPTED FILE-----
    '';
  };
  age.secrets.wallabag-jfly-client-secret = {
    owner = "jeremy";
    rooterEncrypted = ''
      -----BEGIN AGE ENCRYPTED FILE-----
      YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBTUFJYZTYzcXFTb0FXMmxp
      UFdMcE1mcGswR20vWDd3U3JsRllqbGtJTmljCjQ3K0dqTkhiRGVESnhUODd5R3dx
      TUpNMjExZmx1Yi9TQTRTRGJNTiswOEEKLS0tIHMwUHRxeXpGNDl6RlVQMUkwbGs5
      eDF2VFB4V0lta3dJUVFkRnZxbkdZUjAKYhmIWKfzrGSDX5wqcUHRGMAbBHkH/c7R
      /GHCIdnYAgScpSqoZYuCLwuEyi52mUQwBcdPu+a0MCeRO8sW3FCPe5i1C74u+YsY
      xRR7qslieC4E6A==
      -----END AGE ENCRYPTED FILE-----
    '';
  };
  age.secrets.wallabag-jfly-username = {
    owner = "jeremy";
    rooterEncrypted = ''
      -----BEGIN AGE ENCRYPTED FILE-----
      YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSAxTkxWK3M0eXR3Ukd3eDd1
      T000U3p2VmFlNjgvYUhiMGdYOTdwaFZuUXhZCkFiSjZtMVJlTytSckFmaGFlNmY5
      L0UwUmdvVGE3WjVpYzBMMHFaRFl0RU0KLS0tIFpxRTlWUXhzUXVoMTY3cC9ZM2t2
      MmVOa2ErdDdEY005RDlhNVRwcWNMV2cKDdBPq0i7XCStd08I3oLyYrwHM5Bu3GBJ
      2/4s68mEBKzsugvN
      -----END AGE ENCRYPTED FILE-----
    '';
  };
  age.secrets.wallabag-jfly-password = {
    owner = "jeremy";
    rooterEncrypted = ''
      -----BEGIN AGE ENCRYPTED FILE-----
      YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBOUTFJRjB2Y1VEWlBvL253
      blpNdHF5WldieFR2ejVTMkJmeVk0a3Nob2pVClpQMGpSaC8wRkl6eUlxdGxDTGNQ
      di82M3E4MGZFSzA0Z3lSaUZrMUFDbWMKLS0tIGtUT3NuZEh5UCtvcGcvbk1GanBW
      SzMrc1JSR2dKMmZZRUNVTFpGTkdiNVUKoPhfYJ5kfy2/5X2g6tSS5tsgU+ckNb+E
      Y4bXJtWzd1WadB3swYV6Wtp8DTxkC9A=
      -----END AGE ENCRYPTED FILE-----
    '';
  };

  environment.systemPackages = with pkgs; [
    delta # TODO: consolidate with git configuration
    jq # TODO: ~/bin/colorscheme needs this
    (
      pkgs.writeShellApplication {
        name = "wallabag-add";
        runtimeInputs = with pkgs; [ curl ];
        text = ''
          url=$1

          # It's ridiculous that wallabag needs a username and password in *addition* to
          # api tokens. See https://github.com/wallabag/wallabag/issues/2800 for a
          # discussion about this.
          # shellcheck source=/dev/null
          WALLABAG_CLIENT_ID=$(cat ${config.age.secrets.wallabag-jfly-client-id.path})
          WALLABAG_CLIENT_SECRET=$(cat ${config.age.secrets.wallabag-jfly-client-secret})
          WALLABAG_USERNAME=$(cat ${config.age.secrets.wallabag-jfly-username})
          WALLABAG_PASSWORD=$(cat ${age.secrets.wallabag-jfly-password})

          base_url=https://wallabag.snow.jflei.com
          payload=$(curl -sX POST "$base_url/oauth/v2/token" \
              -H "Content-Type: application/json" \
              -H "Accept: application/json" \
              -d '{
                  "grant_type": "password",
                  "client_id": "'"$WALLABAG_CLIENT_ID"'",
                  "client_secret": "'"$WALLABAG_CLIENT_SECRET"'",
                  "username": "'"$WALLABAG_USERNAME"'",
                  "password": "'"$WALLABAG_PASSWORD"'"
              }')

          access_token=$(echo "$payload" | jq --raw-output '.access_token')
          curl -sX POST "$base_url/api/entries.json" \
              -H "Content-Type: application/json" \
              -H "Accept: application/json" \
              -H "Authorization: Bearer $access_token" \
              -d '{"url":"'"$url"'"}' >/dev/null

          echo "Added! $base_url"
        '';
      }
    )
  ];
}
