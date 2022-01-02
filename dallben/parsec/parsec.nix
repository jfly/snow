# Copied from https://github.com/DarthPJB/parsec-gaming-nix/blob/main/default.nix
# TODO: upstream my changes?

{ lib, stdenv, fetchurl, alsaLib, dbus, libGL, libpulseaudio, libva
, openssl, udev, xorg, wayland, autoPatchelfHook }:

stdenv.mkDerivation rec {
  pname = "parsec";
  version = "2021-01-12";

  src = fetchurl {
    url = "https://builds.parsecgaming.com/package/parsec-linux.deb";
    sha256 = "1hfdzjd8qiksv336m4s4ban004vhv00cv2j461gc6zrp37s0fwhc";
  };

  # The upstream deb package is out of date and doesn't work out of the box
  # anymore due to api.parsecgaming.com being down. Auto-updating doesn't work
  # because it doesn't patchelf the dynamic dependencies. Instead, "manually"
  # fetch the latest binaries.
  latest_appdata = fetchurl {
    url = "https://builds.parsecgaming.com/channel/release/appdata/linux/latest";
    sha256 = "078i45q54s2xsqrrldxf5gh187k9wkbqkkwiv3m6vrvkvgpi2fpz";
  };
  latest_parsecd_so = fetchurl {
    url = "https://builds.parsecgaming.com/channel/release/binary/linux/gz/parsecd-150-78.so";
    sha256 = "0rjcrkx82dx78gz973zwvjl8zjwbj9igy6n3abimr678w4mm68nk";
  };

  postPatch = ''
    cp $latest_appdata usr/share/parsec/skel/appdata.json
    cp $latest_parsecd_so usr/share/parsec/skel/parsecd-150-78.so
  '';

  runtimeDependencies = [
    alsaLib (lib.getLib dbus) libGL libpulseaudio libva.out
    (lib.getLib openssl)
    (lib.getLib stdenv.cc.cc)
    (lib.getLib udev)
    xorg.libX11 xorg.libXcursor xorg.libXi xorg.libXinerama xorg.libXrandr
    xorg.libXScrnSaver wayland
  ];

  unpackPhase = ''
    ar p "$src" data.tar.xz | tar xJ
    # Delete outdated copies of files (see comment above about the deb file
    # being out of date). This isn't strictly necessary, but keeps the final
    # artifact a little cleaner.
    rm usr/share/parsec/skel/appdata.json
    rm usr/share/parsec/skel/parsecd-150-28.so
  '';

  installPhase = ''
    mkdir -p $out/bin $out/libexec
    cp usr/bin/parsecd $out/libexec
    cp -r usr/share/parsec/skel $out/libexec
    # parsecd is a small wrapper binary which copies skel/* to ~/.parsec and
    # then runs from there. Unfortunately, it hardcodes the /usr/share/parsec
    # path, and patching that would be annoying. Instead, just reproduce the
    # install logic in a wrapper script.
    cat >$out/bin/parsecd <<EOF
    #! /bin/sh
    mkdir -p \$HOME/.parsec
    ln -sf $out/libexec/skel/* \$HOME/.parsec

    # Need to set LD_LIBRARY_PATH because autoPatchelfHook only patched the
    # main executable, not the .so.
    export LD_LIBRARY_PATH="${lib.makeSearchPath "lib" runtimeDependencies}"

    exec $out/libexec/parsecd "\$@"
    EOF
    chmod +x $out/bin/parsecd
  '';

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  buildInputs = runtimeDependencies;

  meta = with lib; {
    description = "Remotely connect to a gaming PC for a low latency remote computing experience";
    homepage = "https://parsecgaming.com/";
    license = licenses.unfree;
    maintainers = with maintainers; [ delroth ];
  };
}
