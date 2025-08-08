#!/bin/bash

APP_DIR="/usr/share/applications"
DMENU=(dmenu -i)

# Parse flags
while [[ "$1" =~ ^- ]]; do
    if [[ "$1" == "--dir" ]]; then
        shift
        APP_DIR="$1"
        shift
    else
        DMENU+=("$1")
        shift
        [[ "$1" =~ ^[0-9]+$ ]] && DMENU+=("$1") && shift
    fi
done

current_dir="$APP_DIR"

while true; do
    options=$(
        for f in "$current_dir"/*; do
            if [[ -d "$f" ]]; then
                echo "[${f##*/}]"
            elif [[ "$f" == *.desktop ]]; then
                name=$(grep -m1 '^Name=' "$f" | cut -d= -f2-)
                exec=$(grep -m1 '^Exec=' "$f" | cut -d= -f2- | sed 's/ *%[fFuUdDnNickvm]//g')
                [[ -n "$name" && -n "$exec" ]] && echo "$name|$exec"
            fi
        done
    )

    selection=$(echo "$options" | cut -d'|' -f1 | "${DMENU[@]}")

    [[ -z "$selection" ]] && exit 0

    #folder
    if [[ "$selection" == \[*\] ]]; then
        folder_name="${selection:1:-1}"
        current_dir="$current_dir/$folder_name"
        continue
    fi

    #.desktop file
    #if its from the list
    if echo "$options" | grep -Fxq "$selection|$(echo "$options" | grep "^$selection|" | cut -d'|' -f2-)"; then
        cmd=$(echo "$options" | grep "^$selection|" | cut -d'|' -f2-)
        [[ -n "$cmd" ]] && setsid sh -c "$cmd" >/dev/null 2>&1 &
        exit 0
    else
        #if you entered something not from the list

firefox "https://duckduckgo.com/?q=! $selection"
        exit 0
    fi
done
