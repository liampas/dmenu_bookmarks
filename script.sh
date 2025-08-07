#!/bin/bash

DB="/home/liam/.mozilla/firefox/kax45a4s.default-release/places.sqlite"
OUTDIR="bookmarks_files"

mkdir -p "$OUTDIR"

sqlite3 -nullvalue '' -batch "$DB" "SELECT title FROM moz_bookmarks WHERE title IS NOT NULL;" | while IFS= read -r title; do
    # skip empty titles just in case
    [[ -z "$title" ]] && continue
    # sanitize filename
    safe_name=$(echo "$title" | tr -cd '[:alnum:]._-')
    # create empty file
    touch "$OUTDIR/$safe_name"
done

