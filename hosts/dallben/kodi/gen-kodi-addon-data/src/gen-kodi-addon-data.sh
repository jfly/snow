#!/usr/bin/env bash

set -euo pipefail
cd "$(dirname "$0")"

userdata_dir="$HOME/.kodi/userdata"

echo -n "Regenerating $userdata_dir..."
mkdir -p "$userdata_dir"
@rsync@ -a ./ "$userdata_dir"
echo " done!"

# Make everything writeable =(. Kodi expects this, plus we need to go mutate
# some of these files.
echo -n "Marking it all writeable..."
chmod u+w -R "$userdata_dir"
echo " done!"

echo -n "Updating youtube secrets..."
sed -i "s/{{ YOUTUBE_API_KEY }}/@ytApiKey@/g" "$userdata_dir/addon_data/plugin.video.youtube/api_keys.json"
sed -i "s/{{ YOUTUBE_CLIENT_ID }}/@ytClientId@/g" "$userdata_dir/addon_data/plugin.video.youtube/api_keys.json"
sed -i "s/{{ YOUTUBE_CLIENT_SECRET }}/@ytClientSecret@/g" "$userdata_dir/addon_data/plugin.video.youtube/api_keys.json"
echo " done!"

echo -n "Updating mysql password in advancedsettings.xml..."
sed -i "s/{{ MYSQL_PASS }}/@mysqlPass@/g" "$userdata_dir/advancedsettings.xml"
echo " done!"
