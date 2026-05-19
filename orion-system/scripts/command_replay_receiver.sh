#!/bin/bash

PORT="${PORT:-6004}"
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
REPORT_DIR="$SCRIPT_DIR/../reports"
LOG_FILE="$REPORT_DIR/command_replay_protection.log"
USER_DB="$SCRIPT_DIR/../credentials/user_db.txt"
STATE_FILE="$REPORT_DIR/processed_commands.db"

mkdir -p "$REPORT_DIR"
touch "$LOG_FILE"
touch "$STATE_FILE"

echo "=== REPLAY-PROTECTED COMMAND RECEIVER STARTED ==="
echo "Listening on 127.0.0.1:$PORT"
echo "Logging to $LOG_FILE"
echo ""

while true; do
    nc -l 127.0.0.1 "$PORT" | while IFS= read -r line; do
        TS=$(date -Iseconds)

        USER_NAME=$(echo "$line" | grep -o 'USER=[^;]*' | cut -d= -f2)
        ROLE=$(echo "$line" | grep -o 'ROLE=[^;]*' | cut -d= -f2)
        CMD=$(echo "$line" | grep -o 'CMD=[^;]*' | cut -d= -f2)
        COMMAND_ID=$(echo "$line" | grep -o 'COMMAND_ID=[^;]*' | cut -d= -f2)
        MSG_TS=$(echo "$line" | grep -o 'TIMESTAMP=[^;]*' | cut -d= -f2)
        RECEIVED_AUTH=$(echo "$line" | grep -o 'AUTH=[^;]*' | cut -d= -f2)

        echo "[RECEIVED $TS] USER=$USER_NAME ROLE=$ROLE CMD=$CMD COMMAND_ID=$COMMAND_ID"
        echo "[RECEIVED $TS] USER=$USER_NAME ROLE=$ROLE CMD=$CMD COMMAND_ID=$COMMAND_ID MSG_TS=$MSG_TS RAW=$line" >> "$LOG_FILE"

        ENTRY=$(grep "^$USER_NAME:" "$USER_DB")
        if [ -z "$ENTRY" ]; then
            echo "[REJECTED $TS] UNKNOWN USER=$USER_NAME"
            echo "[REJECTED $TS] UNKNOWN USER=$USER_NAME RAW=$line" >> "$LOG_FILE"
            echo ""
            continue
        fi

        DB_ROLE=$(echo "$ENTRY" | cut -d: -f2)
        DB_TOKEN=$(echo "$ENTRY" | cut -d: -f3)

        if [ "$ROLE" != "$DB_ROLE" ]; then
            echo "[REJECTED $TS] ROLE MISMATCH USER=$USER_NAME EXPECTED_ROLE=$DB_ROLE ROLE=$ROLE"
            echo "[REJECTED $TS] ROLE MISMATCH USER=$USER_NAME EXPECTED_ROLE=$DB_ROLE ROLE=$ROLE RAW=$line" >> "$LOG_FILE"
            echo ""
            continue
        fi

        DATA="USER=$USER_NAME;ROLE=$ROLE;CMD=$CMD;COMMAND_ID=$COMMAND_ID;TIMESTAMP=$MSG_TS"
        EXPECTED_AUTH=$(printf "%s" "$DATA" | openssl dgst -sha256 -hmac "$DB_TOKEN" | awk '{print $NF}')

        if [ "$RECEIVED_AUTH" != "$EXPECTED_AUTH" ]; then
            echo "[REJECTED $TS] INVALID HMAC SIGNATURE"
            echo "[REJECTED $TS] INVALID HMAC SIGNATURE RAW=$line" >> "$LOG_FILE"
            echo ""
            continue
        fi

        if grep -q "^$COMMAND_ID$" "$STATE_FILE"; then
            echo "[REJECTED $TS] REPLAY DETECTED: COMMAND_ID=$COMMAND_ID"
            echo "[REJECTED $TS] REPLAY DETECTED: COMMAND_ID=$COMMAND_ID RAW=$line" >> "$LOG_FILE"
            echo ""
            continue
        fi

        echo "$COMMAND_ID" >> "$STATE_FILE"

        AUTHORIZED="no"
        if [ "$ROLE" = "admin" ]; then
            case "$CMD" in
                SET_MODE_NOMINAL|SET_MODE_SAFE|RESET|SHUTDOWN)
                    AUTHORIZED="yes"
                    ;;
            esac
        elif [ "$ROLE" = "operator" ]; then
            case "$CMD" in
                SET_MODE_NOMINAL|SET_MODE_SAFE)
                    AUTHORIZED="yes"
                    ;;
            esac
        fi

        if [ "$AUTHORIZED" != "yes" ]; then
            echo "[REJECTED $TS] UNAUTHORIZED USER=$USER_NAME ROLE=$ROLE CMD=$CMD"
            echo "[REJECTED $TS] UNAUTHORIZED USER=$USER_NAME ROLE=$ROLE CMD=$CMD RAW=$line" >> "$LOG_FILE"
            echo ""
            continue
        fi

        echo "[AUTHORIZED $TS] USER=$USER_NAME ROLE=$ROLE CMD=$CMD COMMAND_ID=$COMMAND_ID"
        echo "[AUTHORIZED $TS] USER=$USER_NAME ROLE=$ROLE CMD=$CMD COMMAND_ID=$COMMAND_ID RAW=$line" >> "$LOG_FILE"

        case "$CMD" in
            SET_MODE_NOMINAL)
                echo "[ACTION] Switching satellite mode to NOMINAL"
                echo "[ACTION $TS] SET_MODE_NOMINAL" >> "$LOG_FILE"
                ;;
            SET_MODE_SAFE)
                echo "[ACTION] Switching satellite mode to SAFE"
                echo "[ACTION $TS] SET_MODE_SAFE" >> "$LOG_FILE"
                ;;
            RESET)
                echo "[ACTION] Simulated satellite reset"
                echo "[ACTION $TS] RESET" >> "$LOG_FILE"
                ;;
            SHUTDOWN)
                echo "[ACTION] Simulated satellite shutdown"
                echo "[ACTION $TS] SHUTDOWN" >> "$LOG_FILE"
                ;;
            *)
                echo "[UNKNOWN COMMAND] $CMD"
                echo "[UNKNOWN $TS] RAW=$line" >> "$LOG_FILE"
                ;;
        esac

        echo ""
    done
done
