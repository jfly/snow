{ pkgs }:

pkgs.python3.pkgs.buildPythonApplication rec {
  pname = "CoverGrid";
  version = "3.2.1";

  format = "other";

  src = pkgs.fetchFromGitLab {
    owner = "coderkun";
    repo = "mcg";
    rev = "v${version}";
    sha256 = "sha256-awPMXGruCB/2nwfDqYlc0Uu9E6VV1AleEZAw9Xdsbt8=";
  };

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
    dateutil
  ];

  # Nixpkgs 17.12.4.3. When using wrapGAppsHook with special derivers you can end up with double wrapped binaries.
  dontWrapGapps = false;
  preFixup = ''
    makeWrapperArgs+=("''${gappsWrapperArgs[@]}")
  '';
}
