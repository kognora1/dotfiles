#!/bin/bash

# Usage:
#   Preview only:  ./rename_photos.sh /path/to/folder
#   Actually do it: ./rename_photos.sh /path/to/folder --apply

FOLDER="$1"
APPLY="$2"

if [ -z "$FOLDER" ]; then
  echo "Usage: $0 /path/to/folder [--apply]"
  exit 1
fi

for file in "$FOLDER"/*.jpg "$FOLDER"/*.JPG "$FOLDER"/*.jpeg "$FOLDER"/*.png "$FOLDER"/*.heic "$FOLDER"/*.HEIC "$FOLDER"/*.mp4 "$FOLDER"/*.MP4 "$FOLDER"/*.mov "$FOLDER"/*.MOV "$FOLDER"/*.mkv "$FOLDER"/*.MKV; do
  [ -f "$file" ] || continue

  # Try to get date from EXIF
  datetime=$(exiftool -d "%Y%m%d_%H%M%S" -DateTimeOriginal -s3 "$file" 2>/dev/null)

  # Fall back to file modification time if no EXIF
  if [ -z "$datetime" ]; then
    datetime=$(date -r "$file" +"%Y%m%d_%H%M%S")
    echo "[WARN] No EXIF for $(basename "$file"), using file date: $datetime"
  fi

  ext="${file##*.}"
  newname="${datetime}.$(echo "$ext" | tr '[:upper:]' '[:lower:]')"  # lowercase extension
  newpath="$FOLDER/$newname"

  if [ "$file" = "$newpath" ]; then
    echo "[SKIP] Already correct: $(basename "$file")"
    continue
  fi

  # Handle duplicates by appending _1, _2 etc
  counter=1
  while [ -f "$newpath" ]; do
    newname="${datetime}_${counter}.$(echo "$ext" | tr '[:upper:]' '[:lower:]')"
    newpath="$FOLDER/$newname"
    ((counter++))
  done

  if [ "$APPLY" = "--apply" ]; then
    mv "$file" "$newpath"
    echo "[RENAMED] $(basename "$file") → $newname"
  else
    echo "[PREVIEW] $(basename "$file") → $newname"
  fi
done
