{ pkgs, lib }:

pkgs.python3.pkgs.buildPythonApplication rec {
  pname = "CoverGrid";
  version = "3.1";

  format = "other";

  # Broken with gobject-introspection setup hook
  # https://github.com/NixOS/nixpkgs/issues/56943
  strictDeps = false;

  src = pkgs.fetchFromGitLab {
    owner = "coderkun";
    repo = "mcg";
    rev = "v${version}";
    sha256 = "sha256-J8xZBhHTY+hxv8V1swk8hc8tQA8wtfTykT581Pcb7SA=";
  };

  patches = [
    # Be more robust when dealing with a corrupted cache
    (pkgs.fetchpatch {
      url = "https://gitlab.com/coderkun/mcg/-/merge_requests/3.patch";
      sha256 = "sha256-v4MMipg8nNny4WOkUdgvPlWx9aF/ttmHjfgzBscqdvQ=";
    })
  ];

  nativeBuildInputs = with pkgs; [
    desktop-file-utils # for update-desktop-database
    glib # for glib-compile-resources
    gobject-introspection
    gtk3
    wrapGAppsHook
    meson
    ninja
  ];

  propagatedBuildInputs = with pkgs.python3.pkgs; [
    pygobject3
  ];

  # Nixpkgs 17.12.4.3. When using wrapGAppsHook with special derivers you can end up with double wrapped binaries.
  dontWrapGapps = false;
  preFixup = ''
    makeWrapperArgs+=("''${gappsWrapperArgs[@]}")
  '';
}
