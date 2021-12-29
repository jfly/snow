import subprocess

import time
import xbmc

# Service that will detect when audio or video starts playing, and turn on the
# reciever/tv as appropriate.  Basic idea from
# https://discourse.osmc.tv/t/turn-tv-on-cec-when-playing-a-video-solved/7446/5

# Whenever we start media, onAVStarted runs and it tells the AVR to turn on and
# switch to the correct input. For some reason the AVR then turns around and
# sends us a pause event over CEC. This causes the video we just started to
# stop playing. Pretty silly.
# To hack around this, whenever the video pauses, we check if the video started
# playing recently (less than START_PAUSE_HACK_SECONDS ago), and if it has, we
# immediately un-pause the video. With this hack, new videos stutter briefly
# as they pause and immediately starts right back up, which isn't great, but
# feels at least moderately better.
# Ideally we'd:
#  - get the receiver to *not* send that CEC pause event. I haven't had
#    any luck trying to figure out how to do *that*, though.
#  - when instructing the AVR to switch inputs, we could put Kodi in a state
#    where it ignores cec keypresses for the next START_PAUSE_HACK_SECONDS
#    seconds. Still a hack, but at least the video wouldn't stutter when
#    starting.
START_PAUSE_HACK_SECONDS = 2

def main():
    player = Player()
    monitor = xbmc.Monitor()

    while not monitor.abortRequested():
        # Sleep/wait for abort for 10 seconds
        if monitor.waitForAbort(10):
            # Abort was requested while waiting. We should exit
            break


class Player(xbmc.Player):
    def __init__(self):
        self._av_started_ts = None

    def onAVStarted(self):
        self._av_started_ts = time.time()
        if self.isPlayingVideo():
            xbmc.log("Looks like you just started playing a video. Attempting to turn on the tv and the receiver", level=xbmc.LOGINFO)
            p = subprocess.run("@receiver@/bin/tv-on.py", check=False, capture_output=True)
            xbmc.log(f"Here's how that went: exit={p.returncode} stdout={p.stdout} stderr={p.stderr}", level=xbmc.LOGINFO)
        else:
            xbmc.log("Looks like you just started playing audio (no video). Attempting to turn on just the receiver", level=xbmc.LOGINFO)
            p = subprocess.run("@receiver@/bin/receiver-on.py", check=False, capture_output=True)
            xbmc.log(f"Here's how that went: exit={p.returncode} stdout={p.stdout} stderr={p.stderr}", level=xbmc.LOGINFO)

    def onPlayBackPaused(self):
        time_since_media_start = None if self._av_started_ts is None else (time.time() - self._av_started_ts)
        if time_since_media_start is not None and time_since_media_start < START_PAUSE_HACK_SECONDS:
            xbmc.log(f"We just started playing media {time_since_media_start:.2f} seconds ago, and we've already paused? I'm going to assume that this is because of a CEC command triggered by the AVR when we switched inputs during onAVStarted and am just going to resume the media.", level=xbmc.LOGINFO)
            self.pause()

if __name__ == '__main__':
    main()
