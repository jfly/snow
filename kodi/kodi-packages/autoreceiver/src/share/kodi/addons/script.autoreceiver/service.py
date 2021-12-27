import subprocess

import xbmc

# Service that will detect when audio or video start playing, and turn on the reciever/tv as appropriate.
# Basic idea from https://discourse.osmc.tv/t/turn-tv-on-cec-when-playing-a-video-solved/7446/5

def main():
    monitor = xbmc.Monitor()

    while not monitor.abortRequested():
        # Sleep/wait for abort for 10 seconds
        if monitor.waitForAbort(10):
            # Abort was requested while waiting. We should exit
            break


class Player(xbmc.Player):
    def onAVStarted(self):
        if self.isPlayingVideo():
            xbmc.log("Looks like you just started playing a video. Attempting to turn on the tv and the receiver", level=xbmc.LOGNOTICE)
            out = subprocess.check_output("@receiver@/bin/tv-on.py", stderr=subprocess.STDOUT)
            xbmc.log("Here's how that went: %s" % out, level=xbmc.LOGNOTICE)
        else:
            xbmc.log("Looks like you just started playing audio (no video). Attempting to turn on just the receiver", level=xbmc.LOGNOTICE)
            out = subprocess.check_output("@receiver@/bin/receiver-on.py", stderr=subprocess.STDOUT)
            xbmc.log("Here's how that went: %s" % out, level=xbmc.LOGNOTICE)

if __name__ == '__main__':
    main()
