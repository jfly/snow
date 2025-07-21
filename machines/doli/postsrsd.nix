{ pkgs, config, ... }:
# We use `postsrsd` to enable Sender Rewriting Scheme (SRS) so mail we forward
# to another domain does not fail SPF.
{
  services.postsrsd = {
    enable = true;
    settings.domains = [ "playground.jflei.com" ];
    secretsFile = config.clan.core.vars.generators.postsrsd-secret.files."secret".path;
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
