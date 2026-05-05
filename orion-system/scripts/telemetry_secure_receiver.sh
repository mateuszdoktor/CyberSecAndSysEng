#!/bin/bash

PORT=5001

SECRET_KEY="orion-shared-secret"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPORT_DIR="$SCRIPT_DIR/reports"
LOG_FILE="$REPORT_DIR/telemetry_secure.log"
STATE_FILE="$REPORT_DIR/last_timestamp.db"

mkdir -p "$REPORT_DIR"
touch "$LOG_FILE"
touch "$STATE_FILE"

echo "=== TELEMETRY RECEIVER STARTED ==="
echo "Listening on port $PORT"
echo "Logging to $LOG_FILE"
echo ""

while true; do
    nc -l 127.0.0.1 "$PORT" | while IFS= read -r line; do
        TS=$(date -Iseconds)
        DATA=$(echo "$line" | sed 's/;SIGNATURE=.*//')
        RECEIVED_SIGNATURE=$(echo "$line" | sed 's/.*;SIGNATURE=//')

        EXPECTED_SIGNATURE=$(printf "%s" "$DATA" | openssl dgst -sha256 -hmac "$SECRET_KEY" | cut -d' ' -f2)

        if [ "$RECEIVED_SIGNATURE" = "$EXPECTED_SIGNATURE" ]; then
            MSG_TIMESTAMP=$(echo "$DATA" | grep -o 'TIMESTAMP=[^;]*' | cut -d= -f2)
            MSG_SAT_ID=$(echo "$DATA" | grep -o 'SAT_ID=[^;]*' | cut -d= -f2)

            LAST_TS=$(grep "^$MSG_SAT_ID=" "$STATE_FILE" | cut -d= -f2)

            if [ -n "$LAST_TS" ] && [[ "$MSG_TIMESTAMP" < "$LAST_TS" || "$MSG_TIMESTAMP" == "$LAST_TS" ]]; then
                echo "[REJECTED $TS] REPLAY DETECTED: $DATA"
                echo "[REJECTED $TS] REPLAY DETECTED: $DATA" >> "$LOG_FILE"
                continue
            fi

            TMP_FILE=$(mktemp)
            grep -v "^$MSG_SAT_ID=" "$STATE_FILE" > "$TMP_FILE" || true
            mv "$TMP_FILE" "$STATE_FILE"
            echo "$MSG_SAT_ID=$MSG_TIMESTAMP" >> "$STATE_FILE"

            echo "[ACCEPTED $TS] $DATA"
            echo "[ACCEPTED $TS] $DATA" >> "$LOG_FILE"
        else
            echo "[REJECTED $TS] INVALID SIGNATURE: $line"
            echo "[REJECTED $TS] INVALID SIGNATURE: $line" >> "$LOG_FILE"
        fi
    done
done
