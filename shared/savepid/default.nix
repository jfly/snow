{pkgs}:

pkgs.writeShellApplication {
  name = "savepid";
  text = builtins.readFile ./savepid;
}
