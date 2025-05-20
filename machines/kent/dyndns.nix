{ config, ... }:

{
  # Create here: https://dash.cloudflare.com/profile/api-tokens. Requires
  # "jflei.com - DNS:Edit". Yes, this is a bit unfortunate. See
  # https://serverfault.com/questions/999850/is-there-a-way-to-craft-a-cloudflare-api-token-such-that-it-can-only-edit-a-spec
  # and
  # https://community.cloudflare.com/t/manage-sub-domain-as-separate-site-for-api-access/311466.
  clan.core.vars.generators.sc-dyndns-api = {
    prompts."token" = {
      type = "hidden";
      persist = true;
    };
  };

  services.cloudflare-dyndns = {
    enable = true;
    domains = [ "sc.jflei.com" ];
    apiTokenFile = config.clan.core.vars.generators.sc-dyndns-api.files."token".path;
  };
}
