{ config, pkgs, ... }:

{
  services.harmonia.enable = true;

  # keypair generated using
  # $ nix-store --generate-binary-cache-key cache.snow.jflei.com ./harmonia.secret ./harmonia.pub
  #
  # Corresponding public key: cache.snow.jflei.com:K6CK1XYbt72oXnBNggcgDwxkeLUeyGtSui2e7ibziqc=
  age.secrets.harmonia-cache-key-secret.rooterEncrypted = ''
    -----BEGIN AGE ENCRYPTED FILE-----
    YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBkeXdnK3FhWExNZWdURGsx
    dHhVa3F4bVFJaDRhZmlHbDhvdzVLclVocGdJCll0TVU2WmltbGs2UGUrR3Y2NVg1
    V3VlUU9LaFhkM2JvT3ZQN3R4T3ZjWk0KLS0tIHU2aldud3UyS0hDalFsTWlqUkZo
    QXZWaXQ3aktjOWI4c0VxY0hXUUN3STgKF+Hm+PHX5SK9Y6dfGaT1mPHypO6HXhFv
    mOg1KBacnEy0SGhB361oWbbxRcCbh94YPHog77PZLRw93pfuHjpE9vfbv+pJ8cVd
    gcheZNILTXwsjXCGyFF64Uwx3ChANDq0mES9eT0FpRs65mNXuNnPqcG+irFW08ob
    U49RrGDcmJDvr9I+5CFKbeM+nx7U
    -----END AGE ENCRYPTED FILE-----
  '';
  services.harmonia.signKeyPath = config.age.secrets.harmonia-cache-key-secret.path;

  environment.systemPackages = with pkgs; [
    # needed to build various flakes that use fetchGit
    git
  ];
}
