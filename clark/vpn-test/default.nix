{ ... }:

{
  image = "ubuntu:20.04";
  entrypoint = "tail";
  cmd = ["-f" "/dev/null"];
  extraOptions = [
    "--network=vpn"
  ];
}
