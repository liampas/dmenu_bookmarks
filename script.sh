#!/bin/bash

DB="/home/liam/.mozilla/firefox/kax45a4s.default-release/places.sqlite"

# Ensure file exists
[[ ! -f "$DB" ]] && { echo "DB not found: $DB"; exit 1; }

# Extract title and type in parallel
mapfile -t titles < <(sqlite3 "$DB" "SELECT title FROM moz_bookmarks WHERE title IS NOT NULL;")
#mapfile -t types < <(sqlite3 "$DB" "SELECT moz_bookmarks.type FROM moz_bookmarks JOIN moz_places ON moz_bookmarks.fk = moz_places.id WHERE moz_places.title IS NOT NULL;")
mapfile -t type < <(sqlite3 "$DB" "SELECT type FROM moz_bookmarks WHERE title IS NOT NULL;")


rm *.desktop


# Output for verification
for i in "${!titles[@]}"; do

    if [ "${type[$i]}" = 2 ]; then
        touch "amogus"
    else
        touch "${titles[$i]}.desktop"
        echo "${type[$i]}" > "${titles[$i]}.desktop"
    fi
done



#   touch "Type: ${types[$i]}"
 #       echo "${types[$i]}" > "Title: ${titles[$i]}.txt"

