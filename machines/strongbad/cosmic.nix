{
  # https://wiki.nixos.org/wiki/COSMIC
  services.displayManager.cosmic-greeter.enable = true;
  services.desktopManager.cosmic.enable = true;
  services.system76-scheduler.enable = true;

  services.displayManager.autoLogin = {
    enable = true;
    user = "mary";
  };

  nixpkgs.overlays = [
    (final: prev: {
      # Fixes an issue where chrome exits fullscreen after 1.5s.
      cosmic-comp = prev.cosmic-comp.overrideAttrs (oldAttrs: {
        patches = oldAttrs.patches or [ ] ++ [
          (final.fetchpatch {
            name = "fix(shell): take presentation feedback from fullscreen surfaces";
            url = "https://github.com/pop-os/cosmic-comp/commit/3b8bac8335ed017a70f1ffe865c86d1ffe07c0cb.diff";
            hash = "sha256-kBlk5vA12+UNdDAd08YycTtc1wFdT1czBeGzf9grjkg=";
          })
        ];
      });
    })
  ];
}
