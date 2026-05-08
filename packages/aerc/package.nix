{
  lib,
  aerc,
  makeWrapper,
  symlinkJoin,
  writeTextFile,
  linkFarm,
  fetchpatch,
}:
let
  toIniFile =
    name: conf:
    writeTextFile {
      name = name;
      text = lib.generators.toINI { } conf;
    };

  # See "TEMPLATES" in `man 5 aerc-config`
  templates = {
    quoted-reply = ''
      X-Mailer: aerc {{version}}

      {{ if has "[Gmail]" .OriginalLabels -}}
      FYI: My personal email address is now me@jfly.fyi. I'll continue to
      receive emails here indefinitely, but I'd appreciate it if you would
      update your address book.

      {{ end }}
      On {{dateFormat (.OriginalDate | toLocal) "Mon Jan 2, 2006 at 3:04 PM MST"}}, {{.OriginalFrom | names | join ", "}} wrote:
      {{ if eq .OriginalMIMEType "text/html" -}}
      {{- exec `html` .OriginalText | trimSignature | quote -}}
      {{- else -}}
      {{- trimSignature .OriginalText | quote -}}
      {{- end}}
      {{- with .Signature }}

      {{.}}
      {{- end }}
    '';
  };

  templateDir = linkFarm "aerc-templates" (
    lib.mapAttrsToList (name: text: {
      inherit name;
      path = writeTextFile {
        inherit name text;
      };
    }) templates
  );

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

    templates = (lib.mapAttrs (name: _text: name) templates) // {
      template-dirs = templateDir;
    };
  };

  accountsConf = toIniFile "accounts.conf" {
    jfly = {
      source = "jmap+oauthbearer://me%40jfly.fyi@api.fastmail.com:443/.well-known/jmap";
      source-cred-cmd = "fastmail-api-token-jfly";
      outgoing = "jmap://";
      from = "Jeremy Fleischman <me@jfly.fyi>";
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
  paths = [
    (aerc.overrideAttrs (oldAttrs: {
      patches = oldAttrs.patches or [ ] ++ [
        (fetchpatch {
          name = "Add `OriginalLabels` to `templateData`";
          url = "https://lists.sr.ht/~rjarry/aerc-devel/patches/69336/mbox";
          hash = "sha256-NmvuONllc6SpFs2z67rkD6qFLVAuwu5pt4mwKCiiBmM=";
        })
      ];
    }))
  ];
  buildInputs = [ makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/aerc \
      --add-flags "--aerc-conf=${aercConf}" \
      --add-flags "--accounts-conf=${accountsConf}" \
      --add-flags "--binds-conf=${./binds.conf}"
  '';
}
