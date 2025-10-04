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

# Copy config.json template and startup script
COPY config.json /app/config.json
COPY start.sh /app/start.sh

# Download and install V2Ray binary directly
RUN curl -L https://github.com/v2fly/v2ray-core/releases/latest/download/v2ray-linux-64.zip -o /tmp/v2ray.zip \
    && mkdir -p /usr/local/bin /usr/local/share/v2ray /usr/local/etc/v2ray \
    && unzip /tmp/v2ray.zip -d /tmp/v2ray \
    && cp /tmp/v2ray/v2ray /usr/local/bin/ \
    && cp /tmp/v2ray/geoip.dat /tmp/v2ray/geosite.dat /usr/local/share/v2ray/ \
    && chmod +x /usr/local/bin/v2ray /app/start.sh \
    && rm -rf /tmp/v2ray /tmp/v2ray.zip

# Expose default port (can be overridden by V2RAY_PORT)
EXPOSE 9527

# Run startup script
CMD ["/app/start.sh"]
