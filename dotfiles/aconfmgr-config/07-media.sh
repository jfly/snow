### MPD
AddPackage mpd # Flexible, powerful, server-side application for playing music
# TODO: figure out why mpd is so messy
IgnorePath '/var/lib/mpd/*'

AddPackage mpc # Minimalist command line interface to MPD
AddPackage ncmpcpp # Almost exact clone of ncmpc with some new features
AddPackage --foreign mcg # A covergrid for the Music Player Daemon.
AddPackage --foreign vimpc-git # Vi/vim inspired client for Music Player Daemon (MPD)
cat > "$(CreateFile /etc/acpi/events/cd_play)" <<EOF
event=cd/play
action=xdotool key --clearmodifiers XF86AudioPlay
EOF

### Media editing (images, audio, video)
AddPackage gimp # GNU Image Manipulation Program
AddPackage inkscape # Professional vector graphics editor
AddPackage audacity # A program that lets you manipulate digital audio waveforms
AddPackage avidemux-qt # Graphical tool to edit video (filter/re-encode/split) - Qt GUI
AddPackage audacity # A program that lets you manipulate digital audio waveforms
AddPackage avidemux-qt # Graphical tool to edit video (filter/re-encode/split) - Qt GUI
