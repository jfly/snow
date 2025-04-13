{ config, ... }:
# We use `postsrsd` to enable Sender Rewriting Scheme (SRS) so mail we forward
# to another domain does not fail SPF.
{
  services.postsrsd = {
    enable = true;
    domains = [ "playground.jflei.com" ];
    secretsFile = config.age.secrets.postsrsd-secret.path;
  };

  # Configure postfix as per
  # https://github.com/roehling/postsrsd?tab=readme-ov-file#postfix-setup
  services.postfix.config = {
    sender_canonical_maps = "socketmap:unix:/run/postsrsd/socket:forward";
    sender_canonical_classes = "envelope_sender";

    recipient_canonical_maps = "socketmap:unix:/run/postsrsd/socket:reverse";
    recipient_canonical_classes = "envelope_recipient, header_recipient";
  };

  # ```
  # dd if=/dev/random bs=18 count=1 status=none | base64
  # ```
  age.secrets.postsrsd-secret.rooterEncrypted = ''
    -----BEGIN AGE ENCRYPTED FILE-----
    YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBpTUdlUkJXbUtWeUdaeENp
    VzBPMDF6K2Uwa3EwdVpmZGNIOENQNnB3ekYwCkl5ejZhSjI5S0dpTU1FRTFoT05D
    dkNDL21CVTAxSTdMSGF1aHV5UURZWmsKLS0tIHI0ZmZwM3llWGVyaGNJcGxJc25j
    SWI4dlp3NVduV2Y0Z1ZQWWNuWHlrREUKkzP9WRw7r3OMadsPnP/dkJmcqMWYpqJB
    Z8Fv0pb75ZRraUlNST0HSBMxZdxR0wwIaBLGhJeKo0Q=
    -----END AGE ENCRYPTED FILE-----
  '';
}
