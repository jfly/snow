{ pkgs }:

let
  fonts = pkgs.callPackage ./fonts.nix { };
in
pkgs.writeShellScript "kobo-install.sh" ''
  KOBO_SANITY_CHECK_DIR=/mnt/kobo/.kobo
  if [ ! -d "$KOBO_SANITY_CHECK_DIR" ]; then
    echo "Could not find $KOBO_SANITY_CHECK_DIR. Aborting." >/dev/stderr
    exit 1
  fi
  ${pkgs.rsync}/bin/rsync --archive --copy-links --delete ${fonts}/ /mnt/kobo/fonts
  echo "Successfully installed fonts on your kobo!"
''
