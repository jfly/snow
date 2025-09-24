{
  lib,
  inputs',
  config,
  pkgs,
  ...
}:
let
  fromEmail = "hello@ramfly.net";
  msmtprc = pkgs.writeTextFile {
    name = "msmtprc";
    text = ''
      account        fastmail
      host           smtp.fastmail.com
      port           465
      tls on
      tls_starttls   off
      auth           on
      from           ${fromEmail}
      user           ${fromEmail}
      passwordeval   cat $CREDENTIALS_DIRECTORY/fastmail-app-password

      account default : fastmail
    '';
  };
  myMsmtp = pkgs.symlinkJoin {
    name = "msmtp";
    paths = [ pkgs.msmtp ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/msmtp --add-flags "--file=${msmtprc}"
    '';
    inherit (pkgs.msmtp) meta;
  };
in
{
  clan.core.vars.generators.brbd-sync = {
    prompts."baserow-api-key" = {
      description = ''
        Baserow API key
      '';
      persist = true;
    };
    prompts."baserow-table-id" = {
      description = ''
        Baserow table id
      '';
      persist = true;
    };
    prompts."buttondown-api-key" = {
      description = ''
        Buttondown API key (<https://buttondown.com/requests/api-key/>)
      '';
      persist = true;
    };
  };

  clan.core.vars.generators.heathchecks-io-brbd-sync = {
    prompts.url = {
      description = "Url to ping after a successful run";
      persist = true;
    };
  };

  clan.core.vars.generators.fastmail-app-password = {
    prompts.password = {
      description = "Fastmail app password for ${fromEmail} (https://app.fastmail.com/settings/security/apps)";
      persist = true;
    };
  };

  clan.core.vars.generators.brbd-sync-to-email = {
    prompts.email = {
      description = "Email address to mail brbd-sync results to";
      persist = true;
    };
  };

  systemd.services.brbd-sync = {
    description = "brbd-sync";
    environment = {
      BASEROW_TAGS_COLUMNS = "Interest";
      BASEROW_METADATA_COLUMNS = "Full Name";
    };
    script = ''
      set -euo pipefail

      export BASEROW_API_KEY=$(< "$CREDENTIALS_DIRECTORY/baserow-api-key")
      export BASEROW_TABLE_ID=$(< "$CREDENTIALS_DIRECTORY/baserow-table-id")
      export BUTTONDOWN_API_KEY=$(< "$CREDENTIALS_DIRECTORY/buttondown-api-key")

      echo "Running brbd-sync..."
      output=$(mktemp)
      ${lib.getExe inputs'.brbd-sync.packages.default} --no-dry-run 2>&1 | tee "$output"
      echo "Running brbd-sync... done!"

      # Email the results.
      to_email=$(< "$CREDENTIALS_DIRECTORY/to-email")
      echo "Emailing the results to $to_email..."
      ${lib.getExe myMsmtp} $to_email <<EOF
      Subject: brbd-sync results
      To: $to_email

      Results:

      $(< "$output")
      EOF
      echo "Emailing the results to $to_email... done!"

      # Ping the success url.
      echo "Pinging the success url..."
      ${lib.getExe pkgs.curl} --silent --max-time 10 --retry 5 "$(< "$CREDENTIALS_DIRECTORY/success-url")"
      echo "Pinging the success url... done!"
    '';
    serviceConfig = {
      Type = "oneshot";
      DynamicUser = true;

      Restart = "on-failure";
      RestartSec = 5;

      LoadCredential = [
        "baserow-api-key:${config.clan.core.vars.generators.brbd-sync.files."baserow-api-key".path}"
        "baserow-table-id:${config.clan.core.vars.generators.brbd-sync.files."baserow-table-id".path}"
        "buttondown-api-key:${config.clan.core.vars.generators.brbd-sync.files."buttondown-api-key".path}"
        "success-url:${config.clan.core.vars.generators.heathchecks-io-brbd-sync.files."url".path}"
        "fastmail-app-password:${
          config.clan.core.vars.generators.fastmail-app-password.files."password".path
        }"
        "to-email:${config.clan.core.vars.generators.brbd-sync-to-email.files."email".path}"
      ];
    };

    # Retry up to 3 times before giving up.
    unitConfig = {
      StartLimitIntervalSec = "5 min";
      StartLimitBurst = 3;
    };
  };

  systemd.timers.brbd-sync = {
    description = "Run brbd-sync";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = "30m";
    };
  };
}
