#!/bin/bash

DB="/home/liam/.mozilla/firefox/kax45a4s.default-release/places.sqlite"
ROOT_DIR="firefox_bookmarks"

# Clean previous output
rm -rf "$ROOT_DIR"
mkdir -p "$ROOT_DIR"

# Step 1: Read all bookmarks info into arrays:
# id, title, type, parent

mapfile -t ids < <(sqlite3 "$DB" "SELECT id FROM moz_bookmarks WHERE title IS NOT NULL;")
mapfile -t titles < <(sqlite3 "$DB" "SELECT title FROM moz_bookmarks WHERE title IS NOT NULL;")
mapfile -t types < <(sqlite3 "$DB" "SELECT type FROM moz_bookmarks WHERE title IS NOT NULL;")
mapfile -t parents < <(sqlite3 "$DB" "SELECT parent FROM moz_bookmarks WHERE title IS NOT NULL;")
mapfile -t fks < <(sqlite3 "$DB" "SELECT fk FROM moz_bookmarks WHERE title IS NOT NULL;")

# Step 2: Build a map of id->parent and id->title and id->type (associative arrays)
declare -A PARENT_MAP
declare -A TITLE_MAP
declare -A TYPE_MAP

for i in "${!ids[@]}"; do
    PARENT_MAP[${ids[$i]}]=${parents[$i]}
    TITLE_MAP[${ids[$i]}]="${titles[$i]}"
    TYPE_MAP[${ids[$i]}]=${types[$i]}
done

# Build a map of place_id -> URL
declare -A URL_MAP
while IFS='|' read -r id url; do
    URL_MAP[$id]="$url"
done < <(sqlite3 "$DB" "SELECT id, url FROM moz_places;")


# Step 3: Function to get full folder path by recursively walking parents
get_path() {
    local id=$1
    local path=""

    while true; do
        local t=${TYPE_MAP[$id]}
        local title=${TITLE_MAP[$id]}
        local parent=${PARENT_MAP[$id]}

        # If folder and title exists, prepend folder name
        if [[ "$t" == "2" && -n "$title" ]]; then
            # sanitize folder name
            local safe_title=$(echo "$title" | tr -cd '[:alnum:]._ -')
            path="$safe_title/$path"
        fi

        # Stop at root bookmarks (usually parent 0 or no parent)
        if [[ "$parent" == "0" || -z "$parent" || "$id" == "$parent" ]]; then
            break
        fi

        id=$parent
    done

    echo "$path"
}

# Step 4: Iterate and create folders/files
for i in "${!ids[@]}"; do
    id=${ids[$i]}
    type=${TYPE_MAP[$id]}
    title=${TITLE_MAP[$id]}

    # sanitize file/folder name
    safe_title=$(echo "$title" | tr -cd '[:alnum:]._ -')

    # get parent folder path relative to root
    folder_path=$(get_path "$id")

    # full path to create
    full_path="$ROOT_DIR/$folder_path"

    if [[ "$type" == "2" ]]; then
        # folder
        mkdir -p "$full_path"
elif [[ "$type" == "1" ]]; then
    mkdir -p "$full_path"
    fk=${fks[$i]}
    url="${URL_MAP[$fk]}"
    {
        echo "[Desktop Entry]"
        echo "Version=1.0"
        echo "Type=Application"
        echo "Name=$safe_title"
        echo "Exec=firefox \"$url\""
        echo "Categories=Bookmarks"
        echo "Comment=$url"
    } > "$full_path/$safe_title.desktop"
    fi
done
