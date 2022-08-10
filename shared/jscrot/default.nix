{pkgs}:

let bell = pkgs.runCommand "" {} ''
  cp ${./bell.oga} $out
'';
in
pkgs.writeShellApplication {
  name = "jscrot";
  runtimeInputs = [
    pkgs.xclip
    pkgs.maim
    pkgs.python3
    pkgs.byzanz
    pkgs.pulseaudio  # provides paplay
    (pkgs.callPackage ../savepid { })
  ];
  text = builtins.replaceStrings ["./bell.oga"] [(builtins.toString bell)] (builtins.readFile ./jscrot);
}
