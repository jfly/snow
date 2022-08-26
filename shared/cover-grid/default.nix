{ pkgs , lib }:

pkgs.python3.pkgs.buildPythonApplication rec {
  pname = "CoverGrid";
  version = "3.0.1";

  # Disable tests: this project doesn't have any, and test collection is
  # broken because some of the .py files aren't importable unless you've
  # actually installed the package (with its resource files).
  doCheck = false;

  # Broken with gobject-introspection setup hook
  # https://github.com/NixOS/nixpkgs/issues/56943
  strictDeps = false;

  src = pkgs.fetchFromGitLab {
    owner = "coderkun";
    repo = "mcg";
    rev = "v${version}";
    sha256 = "sha256-RfxYqF4YIpQ/fejN+5B8seK4u0heJ8THeQ9jlZjVW8I=";
  };

  patches = [
    # Fix build ordering issues
    (pkgs.fetchpatch {
      url = "https://gitlab.com/coderkun/mcg/-/merge_requests/2.patch";
      sha256 = "sha256-go4dKCvMBtbHUQWHIrYlI1YR977DA68ccQZDIRMwLRY=";
    })
  ];

  nativeBuildInputs = with pkgs; [
    glib # for glib-compile-resources
    gobject-introspection
    gtk3
    wrapGAppsHook
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
