{ config, ... }:

{
  # Create here: https://dash.cloudflare.com/profile/api-tokens. Requires
  # "jflei.com - DNS:Edit". Yes, this is a bit unfortunate. See
  # https://serverfault.com/questions/999850/is-there-a-way-to-craft-a-cloudflare-api-token-such-that-it-can-only-edit-a-spec
  # and
  # https://community.cloudflare.com/t/manage-sub-domain-as-separate-site-for-api-access/311466.
  age.secrets.sc-dyndns-api-token.rooterEncrypted = ''
    -----BEGIN AGE ENCRYPTED FILE-----
    YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBBeFptUmJ4VCs5Q0o3UWhs
    RjdaZmtTVFRROEVvajdDZ0Z5dUk3cUlzbnhZClRpbko0M2tpYjUyNEkrazArNHFD
    U1RuYWRxWlZJV0dKLy9QL1BtY3VybWMKLS0tIDZKOFFZU0tkaFg5QmVDK0txK1l2
    NmpVT3liMEs0ckZwZE42OEg1TTJ5ZjgKmhwl1IwuTIJNxmiTmMudJZdS+8bxyCdq
    ojkI348kiAbbmKemF8sy46/kkpR93GpxtfAooA0SWvDGUpL6kOUPqGb395e8u6XI
    -----END AGE ENCRYPTED FILE-----
  '';

  services.cfdyndns = {
    enable = true;
    records = [ "sc.jflei.com" ];

    email = "jeremyfleischman@gmail.com";
    apiTokenFile = config.age.secrets.sc-dyndns-api-token.path;
  };
}
