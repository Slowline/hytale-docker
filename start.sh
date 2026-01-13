#!/bin/bash
set -e

# -------------------------------
# Auto-update Hytale server
# -------------------------------
VERSION_FILE="/hytale/Server/version.txt"
JAR_FILE="/hytale/Server/HytaleServer.jar"
DOWNLOADER_BIN="${DOWNLOADER_BIN:-hytale-downloader}"

# Always record the currently available downloader-reported version for visibility/debugging.
# We'll use it to decide whether we need to download/unpack a new server.
CURRENT_VERSION_RAW="$($DOWNLOADER_BIN -print-version 2>&1 || true)"
CURRENT_VERSION="$(echo "$CURRENT_VERSION_RAW" | tr -d '\r' | tail -n 1)"
mkdir -p "$(dirname "$VERSION_FILE")"

if [ -z "$CURRENT_VERSION" ]; then
    echo "WARNING: Could not determine current version from downloader (-print-version). Output was:"
    echo "$CURRENT_VERSION_RAW"
fi

PREVIOUS_VERSION=""
if [ -f "$VERSION_FILE" ]; then
    PREVIOUS_VERSION="$(tr -d '\r' < "$VERSION_FILE" | tail -n 1)"
fi

echo "$CURRENT_VERSION" > "$VERSION_FILE"

if [ "$ENABLE_AUTO_UPDATE" = "true" ]; then
    # If the Jar is missing (e.g., empty/new volume or partial install), force a download even when version.txt exists.
    NEED_DOWNLOAD="false"
    if [ ! -f "$JAR_FILE" ]; then
        NEED_DOWNLOAD="true"
        echo "Auto-update enabled. Server jar missing ($JAR_FILE). Forcing download..."
    elif [ -n "$PREVIOUS_VERSION" ] && [ -n "$CURRENT_VERSION" ] && [ "$PREVIOUS_VERSION" = "$CURRENT_VERSION" ]; then
        echo "Auto-update enabled. Version unchanged ($CURRENT_VERSION). Skipping download."
    else
        NEED_DOWNLOAD="true"
    fi

    if [ "$NEED_DOWNLOAD" = "true" ]; then
        if [ -z "$PREVIOUS_VERSION" ]; then
            echo "Auto-update enabled. No previous version found. Downloading for the first time..."
        else
            echo "Auto-update enabled. New version detected ($PREVIOUS_VERSION -> $CURRENT_VERSION). Downloading update..."
        fi

        DOWNLOAD_ZIP="/hytale/game.zip"

        set +e
    $DOWNLOADER_BIN -download-path "$DOWNLOAD_ZIP"
        EXIT_CODE=$?
        set -e

        if [ $EXIT_CODE -ne 0 ]; then
            echo "Downloader error: $EXIT_CODE"
            if grep -q "403 Forbidden" <<< "$($DOWNLOADER_BIN -print-version 2>&1 || true)"; then
                if [ "${SKIP_DELETE_ON_FORBIDDEN:-false}" = "true" ]; then
                    echo "403 Forbidden detected! SKIP_DELETE_ON_FORBIDDEN=true, keeping downloader credentials."
                else
                    echo "403 Forbidden detected! Clearing downloader credentials..."
                    rm -f ~/.hytale-downloader-credentials.json
                fi
            fi
            exit $EXIT_CODE
        fi

        if [ ! -f "$DOWNLOAD_ZIP" ]; then
            echo "ERROR: Download expected at $DOWNLOAD_ZIP but file not found."
            exit 1
        fi

        echo "Unpacking $DOWNLOAD_ZIP into /hytale ..."

    # Remove the old jar so the new one is guaranteed to be used.
    rm -f "$JAR_FILE"

        unzip -o "$DOWNLOAD_ZIP" -d /hytale
        rm -f "$DOWNLOAD_ZIP"
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

# Additional JVM options
[ -n "$JAVA_CMD_ADDITIONAL_OPTS" ] && JAVA_CMD+=" $JAVA_CMD_ADDITIONAL_OPTS"

# Add AOT cache if enabled
if [ "$USE_AOT_CACHE" = "true" ] && [ -f "HytaleServer.aot" ]; then
    JAVA_CMD+=" -XX:AOTCache=HytaleServer.aot"
fi

ARGS="--assets $ASSETS_PATH --auth-mode $AUTH_MODE"

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