#!/bin/bash

HOST="127.0.0.1"
PORT="${PORT:-7005}"

USER_NAME="$1"
ROLE="$2"
CMD="$3"
REQUEST_ID="$4"

if [ -z "$USER_NAME" ] || [ -z "$ROLE" ] || [ -z "$CMD" ]; then
    echo "Usage: $0 <user> <role> <command> [request_id]"
    echo "Example: $0 alice operator SET_MODE_SAFE"
    echo "Example: $0 bob admin CONFIRM REQ-12345"
    echo ""
    echo "Optional: PORT=7005 $0 alice operator SET_MODE_SAFE"
    exit 1
fi

case "$USER_NAME" in
    alice)
        TOKEN="token-alice-123"
        ;;
    bob)
        TOKEN="token-bob-999"
        ;;
    *)
        TOKEN="unknown"
        ;;
esac

TS=$(date -Iseconds)
COMMAND_ID="CMD-$(date +%Y%m%d%H%M%S)-$RANDOM"

if [ -n "$REQUEST_ID" ]; then
    DATA="USER=$USER_NAME;ROLE=$ROLE;CMD=$CMD;REQUEST_ID=$REQUEST_ID;COMMAND_ID=$COMMAND_ID;TIMESTAMP=$TS"
else
    DATA="USER=$USER_NAME;ROLE=$ROLE;CMD=$CMD;COMMAND_ID=$COMMAND_ID;TIMESTAMP=$TS"
fi

AUTH=$(printf "%s" "$DATA" | openssl dgst -sha256 -hmac "$TOKEN" | awk '{print $NF}')
MESSAGE="$DATA;AUTH=$AUTH"

echo "[SENDING] $MESSAGE"

echo "$MESSAGE" | openssl s_client -quiet -connect "$HOST:$PORT"
