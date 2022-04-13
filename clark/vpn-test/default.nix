{ ... }:

{
  image = "ubuntu:20.04";
  entrypoint = "tail";
  cmd = ["-f" "/dev/null"];
  extraOptions = [
    "--network=vpn"
    # tail seems to ignore SIGINT when it's running as PID 1? Or something.
    # Either way, it results in very slow shutdowns. This fixes/works around
    # that.
    "--init"
  ];
}
