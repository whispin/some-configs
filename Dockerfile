FROM alpine:3.20

# Install dependencies
RUN apk add --no-cache bash curl jq

# Set working directory
WORKDIR /app

# Copy config.json template
COPY config.json /app/config.json

# Create startup script
RUN printf '#!/bin/bash\n\
set -e\n\
\n\
# Install V2Ray\n\
bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)\n\
\n\
# Copy config.json to V2Ray directory\n\
cp /app/config.json /usr/local/etc/v2ray/config.json\n\
\n\
# Replace environment variables in config.json\n\
if [ -n "$ID" ]; then\n\
    jq --arg id "$ID" ".inbounds[0].settings.clients[0].id = \\$id" /usr/local/etc/v2ray/config.json > /tmp/config.json && mv /tmp/config.json /usr/local/etc/v2ray/config.json\n\
fi\n\
\n\
if [ -n "$PORT" ]; then\n\
    jq --argjson port "$PORT" ".inbounds[0].port = \\$port" /usr/local/etc/v2ray/config.json > /tmp/config.json && mv /tmp/config.json /usr/local/etc/v2ray/config.json\n\
fi\n\
\n\
# Start V2Ray\n\
exec /usr/local/bin/v2ray run -c /usr/local/etc/v2ray/config.json\n' > /app/start.sh

# Make startup script executable
RUN chmod +x /app/start.sh

# Expose default port (can be overridden by V2RAY_PORT)
EXPOSE 9527

# Run startup script
CMD ["/app/start.sh"]
