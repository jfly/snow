#!/usr/bin/env/bash

set -e
cd "$(dirname "$0")"

addon_data_dir="$HOME/.kodi/userdata/addon_data"

echo -n "Regenerating $addon_data_dir..."
mkdir -p "$addon_data_dir"
rsync -av ./addon_data/ "$addon_data_dir"
echo " done!"

# Kodi expects the contents of this directory to be writeable. Don't disappoint
# it.
echo "Marking it all writeable..."
chmod u+w -R "$addon_data_dir"
echo " done!"
