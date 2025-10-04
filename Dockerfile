FROM alpine:3.20

# Install dependencies
RUN apk add --no-cache bash curl jq

# Set working directory
WORKDIR /app

# Copy config.json template
COPY config.json /app/config.json

# Create startup script
RUN cat > /app/start.sh << 'EOF'
#!/bin/bash
set -e

# Install V2Ray
bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)

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
EOF

# Make startup script executable
RUN chmod +x /app/start.sh

# Expose default port (can be overridden by V2RAY_PORT)
EXPOSE 9527

# Run startup script
CMD ["/app/start.sh"]
