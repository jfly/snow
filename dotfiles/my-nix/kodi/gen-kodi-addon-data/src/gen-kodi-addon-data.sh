#!/usr/bin/env/bash

set -e
cd "$(dirname "$0")"

userdata_dir="$HOME/.kodi/userdata"

echo -n "Regenerating $userdata_dir..."
mkdir -p "$userdata_dir"
rsync -a ./ "$userdata_dir"
echo " done!"

# Kodi expects the contents of this directory to be writeable. Don't disappoint
# it.
echo -n "Marking it all writeable..."
chmod u+w -R "$userdata_dir"
echo " done!"
