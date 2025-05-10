{ pkgs, config, ... }:
# We use `postsrsd` to enable Sender Rewriting Scheme (SRS) so mail we forward
# to another domain does not fail SPF.
{
  services.postsrsd = {
    enable = true;
    domains = [ "playground.jflei.com" ];
    secretsFile = config.clan.core.vars.generators.postsrsd-secret.files."secret".path;
  };

  # Configure postfix as per
  # https://github.com/roehling/postsrsd?tab=readme-ov-file#postfix-setup
  services.postfix.config = {
    sender_canonical_maps = "socketmap:unix:/run/postsrsd/socket:forward";
    sender_canonical_classes = "envelope_sender";

    recipient_canonical_maps = "socketmap:unix:/run/postsrsd/socket:reverse";
    recipient_canonical_classes = "envelope_recipient, header_recipient";
  };

  clan.core.vars.generators.postsrsd-secret = {
    files."secret" = { };
    runtimeInputs = with pkgs; [
      coreutils
    ];
    script = ''
      dd if=/dev/random bs=18 count=1 status=none | base64 > $out/secret
    '';
  };
}
