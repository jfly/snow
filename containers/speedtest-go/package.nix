{
  pkgs,
  buildGoModule,
  fetchFromGitHub,
}:

let
  pname = "speedtest-go";
  speedtest-go = buildGoModule {
    inherit pname;
    version = "1.1.5-unstable-2023-04-10";

    src = fetchFromGitHub {
      owner = "librespeed";
      repo = pname;
      # `master` at time of writing. The latest release (1.1.5 at time of writing) is missing https://github.com/librespeed/speedtest-go/commit/8e31fe25acc05e2fdc2a2384898b66f6ca1f1291
      rev = "7001fa4fa52945cbc6d4c32200bbcce7bbf6145c";
      hash = "sha256-p8K/X4SEZmJ5shA1YEUV6X2DMWiIiEK+eC6AIMilprI=";
    };

    vendorHash = "sha256-9zq9X+Je0gLOKx/MhkAC3v8wDELx3xmdJ8CgvHD2Ad8=";
  };

in
pkgs.dockerTools.streamLayeredImage {
  name = "speedtest-go";

  config = {
    Cmd = [ "${speedtest-go}/bin/speedtest" ];
    ExposedPorts = {
      "8989" = { };
    };
  };
}
