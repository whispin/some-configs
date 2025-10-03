FROM alpine:3.20
ARG TARGETARCH
ARG TAILSCALE_VERSION=1.88.3
ARG CLOUDFLARED_VERSION=2025.9.1
USER root
RUN apk add --no-cache iptables iproute2 ca-certificates bash curl \
  && apk add --no-cache --virtual=.install-deps tar


RUN curl -sL "https://pkgs.tailscale.com/stable/tailscale_${TAILSCALE_VERSION}_${TARGETARCH}.tgz" \
  | tar -zxf - -C /usr/local/bin --strip=1 \
    tailscale_${TAILSCALE_VERSION}_${TARGETARCH}/tailscaled \
    tailscale_${TAILSCALE_VERSION}_${TARGETARCH}/tailscale


RUN case "${TARGETARCH}" in \
      "amd64") CLOUDFLARED_ARCH="amd64" ;; \
      "arm64") CLOUDFLARED_ARCH="arm64" ;; \
      *) echo "Unsupported architecture: ${TARGETARCH}" && exit 1 ;; \
    esac && \
    curl -sL "https://github.com/cloudflare/cloudflared/releases/download/${CLOUDFLARED_VERSION}/cloudflared-linux-${CLOUDFLARED_ARCH}" \
      -o /usr/local/bin/cloudflared && \
    chmod +x /usr/local/bin/cloudflared

ENV TS_AUTHKEY=""
ENV TS_HOSTNAME="hf-space-fixed"
ENV TS_SOCKET="/tmp/tailscaled.sock"
ENV XDG_CACHE_HOME="/tmp/.cache"

ENV CLOUDFLARED_TOKEN=""
ENV CLOUDFLARED_ENABLED="true"

RUN mkdir -p /tmp/.cache/Tailscale

CMD mkdir -p /tmp/.cache/Tailscale && \
    HOSTNAME_TO_USE="${TS_HOSTNAME:-hf-space-fixed}" && \
    echo "Starting Tailscale with hostname: ${HOSTNAME_TO_USE}" && \
    tailscaled \
      --tun=userspace-networking \
      --socks5-server=localhost:1055 \
      --state=mem: \
      --socket=${TS_SOCKET} 2>&1 & \
    sleep 10 && \
    tailscale --socket=${TS_SOCKET} up \
      --authkey=${TS_AUTHKEY} \
      --hostname="${HOSTNAME_TO_USE}" \
      --accept-dns=false && \
    echo "Tailscale connected successfully with hostname: ${HOSTNAME_TO_USE}" && \
    if [ "${CLOUDFLARED_ENABLED}" = "true" ] && [ -n "${CLOUDFLARED_TOKEN}" ]; then \
      echo "Starting Cloudflared tunnel..." && \
      cloudflared tunnel --no-autoupdate run --token ${CLOUDFLARED_TOKEN} 2>&1 & \
      echo "Cloudflared started successfully" ; \
    else \
      echo "Cloudflared is disabled or token not provided" ; \
    fi && \
    tail -f /dev/null
