# We run cecdaemon rather than using Kodi's built in CEC support.
# This is nice as it lets us continue to use CEC even when Kodi isn't running
# (such as when we're game streaming over Moonlight).
#
# Note: this relies upon disabling Kodi's CEC support, which we do over in
# `nixos-modules/kodi-colusita/default.nix`. Ideally that would be handled by
# the module system and we could disable Kodi's CEC support here instead.
{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    ;

  cfg = config.services.kodi-colusita.cecdaemon;
in
{
  options.services.kodi-colusita.cecdaemon = {
    enable = mkEnableOption "cecdaemon";
  };

  config = mkIf cfg.enable {
    systemd.services.cecdaemon =
      let
        cecConf = {
          tv.name = config.networking.hostName;
          keymap = {
            # Settings largely copied from <https://github.com/simons-public/cecdaemon/blob/master/examples/cecdaemon.conf-example>
            # Select
            "0" = "KEY_ENTER";
            # Up
            "1" = "KEY_UP";
            # Down
            "2" = "KEY_DOWN";
            # Left
            "3" = "KEY_LEFT";
            # Right
            "4" = "KEY_RIGHT";
            # Home
            "9" = "KEY_ESC";
            # Options
            "10" = "KEY_C";
            # Return
            "13" = "KEY_BACKSPACE";
            # Keys 0-9:
            "32" = "KEY_0";
            "33" = "KEY_1";
            "34" = "KEY_2";
            "35" = "KEY_3";
            "36" = "KEY_4";
            "37" = "KEY_5";
            "38" = "KEY_6";
            "39" = "KEY_7";
            "40" = "KEY_8";
            "41" = "KEY_9";
            # Period
            "42" = "KEY_DOT";
            # Enter
            "43" = "KEY_ENTER";
            # Jump
            "50" = "KEY_CYCLEWINDOWS";
            # Play
            # KEY_PLAY would be "more correct", but doesn't play nicely with
            # stuff like YouTube in a web browser.
            # Also, moonlight doesn't support sending media keys to the
            # remote machine:
            # <https://github.com/moonlight-stream/moonlight-qt/pull/1453>.
            "68" = "KEY_SPACE";
            # Stop
            "69" = "KEY_X";
            # Pause
            # KEY_PAUSE would be "more correct", but doesn't play nicely with
            # stuff like YouTube in a web browser.
            # Also, moonlight doesn't support sending media keys to the
            # remote machine:
            # <https://github.com/moonlight-stream/moonlight-qt/pull/1453>.
            "70" = "KEY_SPACE";
            # Fast Forward
            "75" = "KEY_FASTFORWARD";
            # Rewind
            "76" = "KEY_REWIND";
            # Subtitles
            "81" = "KEY_T";
            # Function buttons
            "113" = "KEY_BLUE";
            "114" = "KEY_RED";
            "115" = "KEY_GREEN";
            "116" = "KEY_YELLOW";
          };
        };

        settingsFormat = pkgs.formats.ini { };
        configFile = settingsFormat.generate "cec.conf" cecConf;
      in
      {
        enable = true;
        wantedBy = [ "multi-user.target" ];
        partOf = [ "multi-user.target" ];

        # cecdaemon depends on the uinput kernel module:
        # <https://github.com/pyinput/python-uinput/issues/9#issuecomment-3568271848>.
        after = [ "modprobe@uinput.service" ];
        wants = [ "modprobe@uinput.service" ];

        serviceConfig.ExecStart = "${lib.getExe pkgs.cecdaemon} --config=${configFile}";
      };
  };
}
