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
      satty
      shotgun
      flameshot # TODO: find a dedicated option for selecting a region. Perhaps a patch to `satty`?
    ])
    ++ (with flake'.packages; [
      savepid
    ]);
  text = builtins.replaceStrings [ "./bell.oga" ] [ (toString ./bell.oga) ] (
    builtins.readFile ./jscrot
  );
}
