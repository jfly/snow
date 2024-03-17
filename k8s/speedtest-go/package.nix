{ buildGoModule, fetchFromGitHub }:

let
  pname = "speedtest-go";
in
buildGoModule {
  inherit pname;
  version = "1.1.5-unstable-2023-04-10";

  src = fetchFromGitHub {
    owner = "librespeed";
    repo = pname;
    rev = "7001fa4fa52945cbc6d4c32200bbcce7bbf6145c"; # latest release (1.1.5 at time of writing) is missing https://github.com/librespeed/speedtest-go/commit/8e31fe25acc05e2fdc2a2384898b66f6ca1f1291
    hash = "sha256-p8K/X4SEZmJ5shA1YEUV6X2DMWiIiEK+eC6AIMilprI=";
  };

  vendorHash = "sha256-9zq9X+Je0gLOKx/MhkAC3v8wDELx3xmdJ8CgvHD2Ad8=";
}
