{
  lib,
  aerc,
  makeWrapper,
  symlinkJoin,
  writeTextFile,
}:
let
  toIniFile =
    name: conf:
    writeTextFile {
      name = name;
      text = lib.generators.toINI { } conf;
    };

  aercConf = toIniFile "aerc.conf" {
    ui = {
      dirlist-right = "{{if .Exists}}{{humanReadable .Exists}}{{end}}";
      dirlist-tree = true;
      threading-enabled = true;
      show-thread-context = true;
    };

    filters = {
      "text/plain" = "colorize";
      "text/calendar" = "calendar";
      "message/delivery-status" = "colorize";
      "message/rfc822" = "colorize";
      "text/html" = "html | colorize";
      ".headers" = "colorize";
    };

    compose = {
      address-book-cmd = "khard email --remove-first-line --parsable %s";
    };
  };

  accountsConf = toIniFile "accounts.conf" {
    jfly = {
      source = "jmap+oauthbearer://me%40jfly.fyi@api.fastmail.com:443/.well-known/jmap";
      source-cred-cmd = "fastmail-api-token-jfly";
      outgoing = "msmtp -a jfly-gmail";
      from = "Jeremy Fleischman <jeremyfleischman@gmail.com>";
      default = "Inbox";
      folders-sort = "Inbox";
      folders-exclude = "Sent,Trash,ideas,~ideas/.*";
      use-labels = true;
    };
    ramfly = {
      source = "jmap+oauthbearer://hello%40ramfly.net@api.fastmail.com:443/.well-known/jmap";
      source-cred-cmd = "fastmail-api-token-ramfly";
      outgoing = "jmap://";
      from = "Jeremy Fleischman <hello@ramfly.net>";
      default = "Inbox";
      folders-sort = "Inbox";
      use-labels = true;
    };
  };
in
symlinkJoin {
  inherit (aerc) name meta;
  paths = [ aerc ];
  buildInputs = [ makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/aerc \
      --add-flags "--aerc-conf=${aercConf}" \
      --add-flags "--accounts-conf=${accountsConf}" \
      --add-flags "--binds-conf=${./binds.conf}"
  '';
}
