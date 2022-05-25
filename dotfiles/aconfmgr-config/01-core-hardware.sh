### Disable the obnoxious PC speaker beep.
# Trick from https://wiki.archlinux.org/title/PC_speaker#Disable_PC_Speaker
cat >"$(CreateFile /etc/modprobe.d/nobeep.conf)" <<EOF
blacklist pcspkr
EOF

### Don't suspend on closing the lid.
cat >"$(CreateFile /etc/systemd/logind.conf.d/no-suspend-on-lidswitch.conf)" <<EOF
[Login]
HandleLidSwitch=ignore
EOF
# Configure other things to happen when the lid is closed.
cat >"$(CreateFile /etc/acpi/events/lid)" <<EOF
event=button/lid
action=/home/jeremy/bin/x11-run-as jeremy lid.sh %e
EOF

### Suspend when the user presses the power button.
cat >"$(CreateFile /etc/systemd/logind.conf.d/suspend-on-powerbutton.conf)" <<EOF
[Login]
HandlePowerKey=suspend
EOF

### Prevent unintended wakeups from suspend.
# Without this, suspending with bluetooth devices connected would cause us to
# immediately wake from sleep.
cat >"$(CreateFile /etc/systemd/system/disable-bt-wakeup.service)" <<EOF
# Inspired by https://bbs.archlinux.org/viewtopic.php?pid=1575617#p1575617
# and https://www.reddit.com/r/archlinux/comments/3zxg65/how_to_permanently_change_procacpiwakeup_or/
# and https://wiki.archlinux.org/index.php/Power_management/Suspend_and_hibernate#Instantaneous_wakeups_from_suspend.
[Unit]
Description=Prevent unintended wakeups from suspend

[Service]
ExecStart=/bin/bash -c "echo EHC1 >> /proc/acpi/wakeup; echo XHC >> /proc/acpi/wakeup"

[Install]
WantedBy=multi-user.target
EOF
CreateLink /etc/systemd/system/multi-user.target.wants/disable-bt-wakeup.service /etc/systemd/system/disable-bt-wakeup.service
