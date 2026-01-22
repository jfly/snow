{
  lib,
  bcachefs-tools,
  kmod,
  writers,
}:

writers.writePython3Bin "wait-for-bcachefs-members" {
  # We have project wide checks with treefmt which disagree with flake8.
  doCheck = false;
  makeWrapperArgs = [
    "--prefix"
    "PATH"
    ":"
    (lib.makeBinPath [
      kmod
      bcachefs-tools
    ])
  ];
} (builtins.readFile ./wait-for-bcachefs-members.py)
