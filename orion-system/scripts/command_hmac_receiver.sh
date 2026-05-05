#!/bin/bash

PORT=6003
REPORT_DIR="../reports"
LOG_FILE="$REPORT_DIR/command_hmac_authentication.log"
USER_DB="../credentials/user_db.txt"
SECRET_KEY="orion-shared-secret"
STATE_FILE="../reports/command_last_timestamp.db"

mkdir -p "$REPORT_DIR"
touch "$LOG_FILE"
touch "$STATE_FILE"

echo "=== HMAC AUTHENTICATED COMMAND RECEIVER STARTED ==="
echo "Listening on 127.0.0.1:$PORT"
echo "Logging to $LOG_FILE"
echo ""

while true; do
    nc -l 127.0.0.1 "$PORT" | while IFS= read -r line; do
        TS=$(date -Iseconds)

        DATA=$(echo "$line" | sed 's/;AUTH=.*//')
        RECEIVED_AUTH=$(echo "$line" | sed 's/.*;AUTH=//')
        EXPECTED_AUTH=$(printf "%s" "$DATA" | openssl dgst -sha256 -hmac "$SECRET_KEY" | awk '{print $NF}')

        if [ "$RECEIVED_AUTH" != "$EXPECTED_AUTH" ]; then
            echo "[REJECTED $TS] INVALID HMAC SIGNATURE"
            echo "[REJECTED $TS] INVALID HMAC SIGNATURE RAW=$line" >> "$LOG_FILE"
            echo ""
            continue
        fi

        USER_NAME=$(echo "$DATA" | grep -o 'USER=[^;]*' | cut -d= -f2)
        ROLE=$(echo "$DATA" | grep -o 'ROLE=[^;]*' | cut -d= -f2)
        CMD=$(echo "$DATA" | grep -o 'CMD=[^;]*' | cut -d= -f2)
        MSG_TS=$(echo "$DATA" | grep -o 'TIMESTAMP=[^;]*' | cut -d= -f2)

        LAST_TS=$(grep "^$USER_NAME=" "$STATE_FILE" | cut -d= -f2)
        if [ -n "$LAST_TS" ] && [[ "$MSG_TS" <= "$LAST_TS" ]]; then
            echo "[REJECTED $TS] REPLAY DETECTED USER=$USER_NAME MSG_TS=$MSG_TS LAST_TS=$LAST_TS"
            echo "[REJECTED $TS] REPLAY DETECTED USER=$USER_NAME MSG_TS=$MSG_TS LAST_TS=$LAST_TS RAW=$line" >> "$LOG_FILE"
            echo ""
            continue
        fi

        echo "[RECEIVED $TS] USER=$USER_NAME ROLE=$ROLE CMD=$CMD"
        echo "[RECEIVED $TS] USER=$USER_NAME ROLE=$ROLE CMD=$CMD MSG_TS=$MSG_TS RAW=$line" >> "$LOG_FILE"

        ENTRY=$(grep "^$USER_NAME:" "$USER_DB")
        if [ -z "$ENTRY" ]; then
            echo "[REJECTED $TS] UNKNOWN USER=$USER_NAME"
            echo "[REJECTED $TS] UNKNOWN USER=$USER_NAME RAW=$line" >> "$LOG_FILE"
            echo ""
            continue
        fi

        DB_ROLE=$(echo "$ENTRY" | cut -d: -f2)

        if [ "$ROLE" != "$DB_ROLE" ]; then
            echo "[REJECTED $TS] ROLE MISMATCH for USER=$USER_NAME, expected ROLE=$DB_ROLE but got ROLE=$ROLE"
            echo "[REJECTED $TS] ROLE MISMATCH USER=$USER_NAME EXPECTED_ROLE=$DB_ROLE ROLE=$ROLE RAW=$line" >> "$LOG_FILE"
            echo ""
            continue
        fi

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

        echo "[AUTHORIZED $TS] USER=$USER_NAME ROLE=$ROLE CMD=$CMD"
        echo "[AUTHORIZED $TS] USER=$USER_NAME ROLE=$ROLE CMD=$CMD RAW=$line" >> "$LOG_FILE"

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
