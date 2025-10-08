{
  aerc,
  makeWrapper,
  symlinkJoin,
}:

symlinkJoin {
  inherit (aerc) name meta;
  paths = [ aerc ];
  buildInputs = [ makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/aerc \
      --add-flags "--aerc-conf=${./aerc.conf}" \
      --add-flags "--accounts-conf=${./accounts.conf}" \
      --add-flags "--binds-conf=${./binds.conf}"
  '';
}
