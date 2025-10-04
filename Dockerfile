FROM debian:bookworm-slim

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    jq \
    unzip \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy config.json template
COPY config.json /app/config.json

# Download and install V2Ray binary directly
RUN curl -L https://github.com/v2fly/v2ray-core/releases/latest/download/v2ray-linux-64.zip -o /tmp/v2ray.zip \
    && mkdir -p /usr/local/bin /usr/local/share/v2ray /usr/local/etc/v2ray \
    && unzip /tmp/v2ray.zip -d /tmp/v2ray \
    && cp /tmp/v2ray/v2ray /usr/local/bin/ \
    && cp /tmp/v2ray/geoip.dat /tmp/v2ray/geosite.dat /usr/local/share/v2ray/ \
    && chmod +x /usr/local/bin/v2ray \
    && rm -rf /tmp/v2ray /tmp/v2ray.zip

# Create startup script
RUN printf '#!/bin/bash\n\
set -e\n\
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
