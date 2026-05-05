#!/bin/bash

HOST="127.0.0.1"
PORT="${PORT:-6003}"
SECRET_KEY="orion-shared-secret"

USER_NAME="$1"
ROLE="$2"
CMD="$3"

if [ -z "$USER_NAME" ] || [ -z "$ROLE" ] || [ -z "$CMD" ]; then
    echo "Usage: $0 <user> <role> <command>"
    echo "Example: $0 alice operator SET_MODE_SAFE"
    echo ""
    echo "Optional: PORT=6003 $0 alice operator SET_MODE_SAFE"
    exit 1
fi

TS=$(date -Iseconds)
DATA="USER=$USER_NAME;ROLE=$ROLE;CMD=$CMD;TIMESTAMP=$TS"
AUTH=$(printf "%s" "$DATA" | openssl dgst -sha256 -hmac "$SECRET_KEY" | awk '{print $NF}')
MESSAGE="$DATA;AUTH=$AUTH"
echo "[SENDING] $MESSAGE"

if nc -h 2>&1 | grep -q -- "-q"; then
    echo "$MESSAGE" | nc -q 0 "$HOST" "$PORT"
elif nc -h 2>&1 | grep -iq "ncat"; then
    echo "$MESSAGE" | nc "$HOST" "$PORT"
else
    echo "$MESSAGE" | nc -N "$HOST" "$PORT"
fi
