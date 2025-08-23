{
  lib,
  fetchFromGitHub,
  buildGoModule,
}:
buildGoModule {
  pname = "librespeed-go";
  version = "1.1.5-unstable-2023-04-10";

  src = fetchFromGitHub {
    owner = "librespeed";
    repo = "speedtest-go";
    # `master` at time of writing. The latest release (1.1.5) is missing
    # <https://github.com/librespeed/speedtest-go/commit/8e31fe25acc05e2fdc2a2384898b66f6ca1f1291>.
    # See <https://github.com/librespeed/speedtest-go/issues/75>.
    rev = "7001fa4fa52945cbc6d4c32200bbcce7bbf6145c";
    hash = "sha256-p8K/X4SEZmJ5shA1YEUV6X2DMWiIiEK+eC6AIMilprI=";
  };

  vendorHash = "sha256-9zq9X+Je0gLOKx/MhkAC3v8wDELx3xmdJ8CgvHD2Ad8=";

  meta = {
    description = "A very lightweight speed test implementation in Go";
    homepage = "https://github.com/librespeed/speedtest-go";
    license = lib.licenses.lgpl3Plus;
    maintainers = with lib.maintainers; [ jfly ];
    mainProgram = "speedtest";
  };
}
