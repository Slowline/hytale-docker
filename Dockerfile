# Base image with Java 25 EA
FROM eclipse-temurin:25.0.1_8-jdk-jammy

LABEL org.opencontainers.image.source="https://github.com/Slowline/hytale-docker"

# Install required utilities
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      wget unzip curl bash ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /hytale

# -------------------------------
# Copy start script and make executable as root
# -------------------------------
COPY start.sh /hytale/start.sh
RUN chmod +x /hytale/start.sh

# -------------------------------
# Download Hytale Downloader CLI
# -------------------------------
RUN wget -O hytale-downloader.zip https://downloader.hytale.com/hytale-downloader.zip && \
    unzip hytale-downloader.zip && \
    rm hytale-downloader.zip && \
    mv hytale-downloader-linux-amd64 hytale-downloader && \
    chmod +x hytale-downloader

# -------------------------------
# Create non-root user and switch
# -------------------------------
RUN useradd -m -d /hytale hytale && \
  chown -R hytale:hytale /hytale
USER hytale
WORKDIR /hytale

# -------------------------------
# Environment variables
# -------------------------------
ENV HYTALE_PORT="5520"
ENV USE_AOT_CACHE="true"
ENV ENABLE_AUTO_UPDATE="true"
ENV SKIP_DELETE_ON_FORBIDDEN="false"
ENV ACCEPT_EARLY_PLUGINS="false"
ENV ALLOW_OP="false"
ENV ASSETS_PATH="/hytale/Assets.zip"
ENV AUTH_MODE="authenticated"
ENV BIND_ADDR="0.0.0.0"
ENV BACKUP_ENABLED="false"
ENV BACKUP_DIR="/hytale/backups"
ENV BACKUP_FREQUENCY="30"
ENV DISABLE_SENTRY="false"

# Expose server port
EXPOSE 5520/udp

# Volume for persistent server data
VOLUME ["/hytale/Server"]

# Start the server
ENTRYPOINT ["/hytale/start.sh"]