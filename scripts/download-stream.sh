#!/bin/bash
source /opt/ffmpeg-webhook/.env

URL=$1
NAME=$2

SAFE_NAME=$(echo "$NAME" | sed 's/[^a-zA-Z0-9._-]/_/g')
[ -z "$SAFE_NAME" ] && SAFE_NAME="stream_$(date +%Y%m%d_%H%M%S)"

OUTPUT="${DOWNLOAD_DIR}/${SAFE_NAME}"

echo "$(date): Starting download: $URL -> $OUTPUT" >> "$LOG_FILE"

if /opt/ffmpeg-webhook/scripts/ffmpeg-progress.py "$URL" "$OUTPUT" "$SAFE_NAME"; then
    echo "$(date): Download completed: $OUTPUT" >> "$LOG_FILE"
else
    echo "$(date): Download FAILED: $OUTPUT" >> "$LOG_FILE"
fi
