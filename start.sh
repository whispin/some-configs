#!/bin/bash
set -e

# Copy config.json to V2Ray directory
cp /app/config.json /usr/local/etc/v2ray/config.json

# Replace environment variables in config.json
if [ -n "$ID" ]; then
    jq --arg id "$ID" '.inbounds[0].settings.clients[0].id = $id' /usr/local/etc/v2ray/config.json > /tmp/config.json && mv /tmp/config.json /usr/local/etc/v2ray/config.json
fi

if [ -n "$PORT" ]; then
    jq --argjson port "$PORT" '.inbounds[0].port = $port' /usr/local/etc/v2ray/config.json > /tmp/config.json && mv /tmp/config.json /usr/local/etc/v2ray/config.json
fi

# Start V2Ray
exec /usr/local/bin/v2ray run -c /usr/local/etc/v2ray/config.json
