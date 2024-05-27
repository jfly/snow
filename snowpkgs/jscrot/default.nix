{ pkgs }:

let
  bell = pkgs.runCommand "" { } ''
    cp ${./bell.oga} $out
  '';
in
pkgs.writeShellApplication {
  name = "jscrot";
  runtimeInputs = with pkgs; [
    xclip
    maim
    python3
    byzanz
    pulseaudio # provides paplay
  ] ++ (with pkgs.snow; [
    flameshot
    savepid
  ]);
  text = builtins.replaceStrings [ "./bell.oga" ] [ (builtins.toString bell) ] (builtins.readFile ./jscrot);
}
