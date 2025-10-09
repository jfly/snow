{ config, ... }:
{
  clan.core.vars.generators.google-oauth-client = {
    prompts.client_id = {
      description = "Client id for a Google OAuth client. See https://github.com/pdobsan/oama for details.";
      persist = true;
    };
    files.client_id.owner = config.snow.user.name;

    prompts.client_secret = {
      description = "Client secret for a Google OAuth client. See https://github.com/pdobsan/oama for details.";
      persist = true;
    };
    files.client_secret.owner = config.snow.user.name;
  };

  clan.core.vars.generators.fastmail-jfly-api-token = {
    prompts.token = {
      description = "Fastmail api token for jfly (https://app.fastmail.com/settings/security/tokens)";
      persist = true;
    };
    files.token.owner = config.snow.user.name;
  };
  clan.core.vars.generators.fastmail-jfly-app-password = {
    prompts.password = {
      description = "Fastmail app password for jfly (https://app.fastmail.com/settings/security/apps)";
      persist = true;
    };
    files.password.owner = config.snow.user.name;
  };

  clan.core.vars.generators.fastmail-ramfly-api-token = {
    prompts.token = {
      description = "Fastmail api token for ramfly (https://app.fastmail.com/settings/security/tokens)";
      persist = true;
    };
    files.token.owner = config.snow.user.name;
  };
  clan.core.vars.generators.fastmail-ramfly-app-password = {
    prompts.password = {
      description = "Fastmail app password for ramfly (https://app.fastmail.com/settings/security/apps)";
      persist = true;
    };
    files.password.owner = config.snow.user.name;
  };
}
