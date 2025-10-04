#!/bin/bash
set -ex

# Copy config.json to V2Ray directory
cp /app/config.json /usr/local/etc/v2ray/config.json

# Replace environment variables in config.json
if [ -n "$ID" ]; then
    echo "Replacing ID with: $ID"
    jq --arg id "$ID" '.inbounds[0].settings.clients[0].id = $id' /usr/local/etc/v2ray/config.json > /tmp/config.json
    if [ $? -eq 0 ]; then
        mv /tmp/config.json /usr/local/etc/v2ray/config.json
    else
        echo "Failed to replace ID"
        exit 1
    fi
fi

if [ -n "$PORT" ]; then
    echo "Replacing PORT with: $PORT"
    jq --arg port "$PORT" '.inbounds[0].port = ($port | tonumber)' /usr/local/etc/v2ray/config.json > /tmp/config.json
    if [ $? -eq 0 ]; then
        mv /tmp/config.json /usr/local/etc/v2ray/config.json
    else
        echo "Failed to replace PORT"
        exit 1
    fi
fi


# Start V2Ray
exec /usr/local/bin/v2ray run -c /usr/local/etc/v2ray/config.json
