{ config, ... }:
{
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
  clan.core.vars.generators.ram-cal-url = {
    prompts.url = {
      description = "ISC URL for ram";
      persist = true;
    };
    files.url.owner = config.snow.user.name;
  };
}
