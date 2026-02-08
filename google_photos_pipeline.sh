#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="$HOME/.google_photos_pipeline.conf"

default_SRC_ZIPS="/mnt/z/GooglePhotoExportZips"
default_WORK_DIR="/mnt/z/PhotoPrismLibrary"
default_PRISM_ORIG="/photoprism_ext4/originals"
default_ARCHIVE_DIR="/mnt/z/PhotoArchivesByYear"
default_MIRROR1="/mnt/g/PhotosArchivedByYear"
default_MIRROR2="/mnt/h/PhotosArchivedByYear"
default_HEIC_LOG="/mnt/z/heic_to_jpeg.log"

load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
        return
    fi

    echo "First‑run setup:"
    read -rp "Path to ZIP files [$default_SRC_ZIPS]: " SRC_ZIPS
    SRC_ZIPS="${SRC_ZIPS:-$default_SRC_ZIPS}"

    read -rp "Working directory [$default_WORK_DIR]: " WORK_DIR
    WORK_DIR="${WORK_DIR:-$default_WORK_DIR}"

    read -rp "PhotoPrism originals directory [$default_PRISM_ORIG]: " PRISM_ORIG
    PRISM_ORIG="${PRISM_ORIG:-$default_PRISM_ORIG}"

    read -rp "Yearly archive directory [$default_ARCHIVE_DIR]: " ARCHIVE_DIR
    ARCHIVE_DIR="${ARCHIVE_DIR:-$default_ARCHIVE_DIR}"

    read -rp "Mirror location 1 [$default_MIRROR1]: " MIRROR1
    MIRROR1="${MIRROR1:-$default_MIRROR1}"

    read -rp "Mirror location 2 [$default_MIRROR2]: " MIRROR2
    MIRROR2="${MIRROR2:-$default_MIRROR2}"

    read -rp "HEIC conversion log file [$default_HEIC_LOG]: " HEIC_LOG
    HEIC_LOG="${HEIC_LOG:-$default_HEIC_LOG}"

    cat > "$CONFIG_FILE" <<EOF
SRC_ZIPS="$SRC_ZIPS"
WORK_DIR="$WORK_DIR"
PRISM_ORIG="$PRISM_ORIG"
ARCHIVE_DIR="$ARCHIVE_DIR"
MIRROR1="$MIRROR1"
MIRROR2="$MIRROR2"
HEIC_LOG="$HEIC_LOG"
EOF

    echo "Configuration saved to $CONFIG_FILE"
}

load_config

HEIC_STAGE="$WORK_DIR/_original_heic"
LOG="/tmp/google_photos_pipeline.log"

mkdir -p "$WORK_DIR" "$HEIC_STAGE" "$ARCHIVE_DIR" "$MIRROR1" "$MIRROR2"
echo "=== Run started: $(date) ===" > "$LOG"

get_year() {
    local f="$1"
    local json="${f%.*}.json"

    if exiftool -d "%Y" -DateTimeOriginal -S -s "$f" 2>/dev/null | grep -qE '^[0-9]{4}$'; then
        exiftool -d "%Y" -DateTimeOriginal -S -s "$f"
        return
    fi

    if [[ -f "$json" ]]; then
        jq -r '.photoTakenTime.formatted' "$json" 2>/dev/null | awk '{print $NF}' | cut -d- -f1
        return
    fi

    date -r "$f" +"%Y"
}

echo "Extracting ZIPs..." | tee -a "$LOG"

for z in "$SRC_ZIPS"/*.zip; do
    [[ -e "$z" ]] || continue
    echo "Extracting: $z" | tee -a "$LOG"
    unzip -o "$z" -d "$WORK_DIR" >> "$LOG" 2>&1
done

find "$WORK_DIR" -type f -name "*.zip" | while read -r inner; do
    echo "Extracting nested ZIP: $inner" | tee -a "$LOG"
    unzip -o "$inner" -d "$(dirname "$inner")" >> "$LOG" 2>&1
    rm -f "$inner"
done

echo "Files after extraction:" | tee -a "$LOG"
find "$WORK_DIR" -type f | tee -a "$LOG"

echo "Staging HEIC files..." | tee -a "$LOG"
find "$WORK_DIR" -maxdepth 1 -type f -iregex ".*\.heic" ! -path "$HEIC_STAGE/*" -exec mv -f {} "$HEIC_STAGE"/ \;

echo "Starting HEIC → JPEG conversion at $(date)" | tee -a "$HEIC_LOG"

find "$HEIC_STAGE" -type f -iregex ".*\.heic" -print0 | while IFS= read -r -d '' HEIC; do
    BASENAME="$(basename "$HEIC" | sed 's/\.[Hh][Ee][Ii][Cc]$//')"
    DEST="$WORK_DIR/${BASENAME}.jpg"

    if [[ -f "$DEST" ]]; then
        echo "SKIPPED (exists): $DEST" | tee -a "$HEIC_LOG"
        continue
    fi

    echo "Converting: $HEIC -> $DEST" | tee -a "$HEIC_LOG"
    convert "$HEIC" "$DEST"
    echo "DONE: $DEST" | tee -a "$HEIC_LOG"
done

echo "Finished HEIC → JPEG conversion at $(date)" | tee -a "$HEIC_LOG"

echo "Copying into PhotoPrism originals..." | tee -a "$LOG"
cp -av "$WORK_DIR"/ "$PRISM_ORIG"/ | tee -a "$LOG"

echo "Building yearly archives..." | tee -a "$LOG"

find "$WORK_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.mp4" -o -iname "*.mov" \) | while read -r f; do
    year=$(get_year "$f")
    [[ "$year" =~ ^[0-9]{4}$ ]] || year="unknown"

    archive="$ARCHIVE_DIR/${year}_Photos.zip"
    zip -9 -u "$archive" "$f" >> "$LOG" 2>&1
done

echo "Mirroring archives..." | tee -a "$LOG"
cp -av "$ARCHIVE_DIR"/ "$MIRROR1"/ | tee -a "$LOG"
cp -av "$ARCHIVE_DIR"/ "$MIRROR2"/ | tee -a "$LOG"

echo "=== Completed successfully: $(date) ===" | tee -a "$LOG"
