#!/bin/bash

DB="/home/liam/.mozilla/firefox/kax45a4s.default-release/places.sqlite"
OUTDIR="bookmarks_files"

mkdir -p "$OUTDIR"

sqlite3 -readonly -separator $'\t' "$DB" "
SELECT b.title, COALESCE(a.content, '')
FROM moz_bookmarks b
LEFT JOIN moz_items_annos a ON a.item_id = b.id
LEFT JOIN moz_anno_attributes aa ON aa.id = a.anno_attribute_id
WHERE b.title IS NOT NULL AND (aa.name = 'bookmarkProperties/description' OR aa.name IS NULL);
" | while IFS=$'\t' read -r title desc; do
    [[ -z "$title" ]] && continue
    safe_name=$(echo "$title" | tr -cd '[:alnum:]._-')
    # Avoid empty or duplicate filenames
    [[ -z "$safe_name" ]] && safe_name="bookmark_$RANDOM"
    echo "$desc" > "$OUTDIR/$safe_name"
done
