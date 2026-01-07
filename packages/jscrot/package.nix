{ flake', pkgs }:

pkgs.writeShellApplication {
  name = "jscrot";
  runtimeInputs =
    (with pkgs; [
      xclip
      maim
      python3
      byzanz
      pulseaudio # provides `paplay`
    ])
    ++ (with flake'.packages; [
      flameshot
      savepid
    ]);
  text = builtins.replaceStrings [ "./bell.oga" ] [ (toString ./bell.oga) ] (
    builtins.readFile ./jscrot
  );
}
