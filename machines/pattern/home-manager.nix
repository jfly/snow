{
  flake,
  config,
  pkgs,
  ...
}:

{
  home-manager.useGlobalPkgs = true;
  home-manager.users.${config.snow.user.name} = (
    import ./home.nix {
      inherit flake config;
    }
  );

  clan.core.vars.generators.wallabag = {
    files."client-id".owner = config.snow.user.name;
    files."client-secret".owner = config.snow.user.name;
    files."username".owner = config.snow.user.name;
    files."password".owner = config.snow.user.name;

    prompts.client-id = {
      type = "line";
      persist = true;
    };
    prompts.client-secret = {
      type = "hidden";
      persist = true;
    };
    prompts.username = {
      type = "line";
      persist = true;
    };
    prompts.password = {
      type = "hidden";
      persist = true;
    };
  };
  environment.systemPackages = with pkgs; [
    delta # TODO: consolidate with git configuration
    difftastic # TODO: consolidate with git configuration
    (pkgs.writeShellApplication {
      name = "wallabag-add";
      runtimeInputs = with pkgs; [ curl ];
      text = ''
        url=$1

        # It's ridiculous that wallabag needs a username and password in *addition* to
        # api tokens. See https://github.com/wallabag/wallabag/issues/2800 for a
        # discussion about this.
        # shellcheck source=/dev/null
        WALLABAG_CLIENT_ID=$(< ${config.clan.core.vars.generators.wallabag.files."client-id".path})
        WALLABAG_CLIENT_SECRET=$(< ${config.clan.core.vars.generators.wallabag.files."client-secret".path})
        WALLABAG_USERNAME=$(< ${config.clan.core.vars.generators.wallabag.files."username".path})
        WALLABAG_PASSWORD=$(< ${config.clan.core.vars.generators.wallabag.files."password".path})

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
    })
  ];
}
