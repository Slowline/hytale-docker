#!/bin/bash
set -e

# -------------------------------
# Auto-update Hytale server
# -------------------------------
if [ "$ENABLE_AUTO_UPDATE" = "true" ]; then
    echo "Auto-update enabled. Downloading latest server..."
    ./hytale-downloader
    EXIT_CODE=$?

    if [ $EXIT_CODE -ne 0 ]; then
        echo "Downloader error: $EXIT_CODE"
        if grep -q "403 Forbidden" <<< "$(./hytale-downloader -print-version 2>&1 || true)"; then
            if [ "${SKIP_DELETE_ON_FORBIDDEN:-false}" = "true" ]; then
                echo "403 Forbidden detected! SKIP_DELETE_ON_FORBIDDEN=true, keeping downloader credentials."
            else
                echo "403 Forbidden detected! Clearing downloader credentials..."
                rm -f ~/.hytale-downloader-credentials.json
            fi
        fi
    fi
else
    echo "Auto-update disabled. Skipping download."
fi

cd /hytale/Server

if [ ! -f "HytaleServer.jar" ]; then
    echo "ERROR: HytaleServer.jar not found!"
    exit 1
fi

# -------------------------------
# Build Java command
# -------------------------------
JAVA_CMD="java"

# Default heap settings
JAVA_XMS="${JAVA_XMS:-4G}"
JAVA_XMX="${JAVA_XMX:-4G}"

# Apply heap settings when set
[ -n "$JAVA_XMS" ] && JAVA_CMD+=" -Xms$JAVA_XMS"
[ -n "$JAVA_XMX" ] && JAVA_CMD+=" -Xmx$JAVA_XMX"

# Add AOT cache if enabled
if [ "$USE_AOT_CACHE" = "true" ] && [ -f "HytaleServer.aot" ]; then
    JAVA_CMD+=" -XX:AOTCache=HytaleServer.aot"
fi

ARGS="--port $HYTALE_PORT --assets $ASSETS_PATH --auth-mode $AUTH_MODE"

# Provider authentication tokens, Only append when env vars are set
[ -n "$SESSION_TOKEN" ] && ARGS="$ARGS --session-token \"$SESSION_TOKEN\""
[ -n "$IDENTITY_TOKEN" ] && ARGS="$ARGS --identity-token \"$IDENTITY_TOKEN\""
[ -n "$OWNER_UUID" ] && ARGS="$ARGS --owner-uuid \"$OWNER_UUID\""

[ "$ACCEPT_EARLY_PLUGINS" = "true" ] && ARGS="$ARGS --accept-early-plugins"
[ "$ALLOW_OP" = "true" ] && ARGS="$ARGS --allow-op"
[ "$DISABLE_SENTRY" = "true" ] && ARGS="$ARGS --disable-sentry"

# Backup options
if [ "$BACKUP_ENABLED" = "true" ]; then
    ARGS="$ARGS --backup --backup-dir $BACKUP_DIR --backup-frequency $BACKUP_FREQUENCY"
fi

ARGS="$ARGS --bind $BIND_ADDR:$HYTALE_PORT"

echo "Starting Hytale server:"
echo "$JAVA_CMD -jar HytaleServer.jar $ARGS"
exec $JAVA_CMD -jar HytaleServer.jar $ARGS