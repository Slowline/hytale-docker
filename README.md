Docker setup for running the Hytale dedicated server.

This container downloads/updates the server on startup using the official Hytale Downloader CLI, then starts `HytaleServer.jar` with the options configured via environment variables.

## Ports

- UDP `5520` (default)

## Environment variables

These are set in `docker-compose.yml`. You can change them there or move them into a `.env` and reference them from Compose.

### Server / networking

- `HYTALE_PORT` (default: `5520`)
  - Server port.
- `BIND_ADDR` (default: `0.0.0.0`)
  - Bind address.

### Assets / auth

- `ASSETS_PATH` (default: `/hytale/Assets.zip`)
  - Path to the server assets zip inside the container.
- `AUTH_MODE` (default: `authenticated`)
  - Authentication mode passed to the server.

#### Server Provider Authentication

You can pass auth tokens to the server. These are **not set by default** and the startup script only adds the flags when the variables are present:

- `SESSION_TOKEN` (optional)
  - Adds `--session-token "<sessionToken>"`
- `IDENTITY_TOKEN` (optional)
  - Adds `--identity-token "<identityToken>"`
- `OWNER_UUID` (optional)
  - Adds `--owner-uuid "<uuid>"`

### Updates

- `ENABLE_AUTO_UPDATE` (default: `true`)
  - If `true`, runs `./hytale-downloader` on every container start.
- `SKIP_DELETE_ON_FORBIDDEN` (default: `false`)
  - If `true`, the startup script will **not** delete `~/.hytale-downloader-credentials.json` when it detects a `403 Forbidden`.

### AOT cache

- `USE_AOT_CACHE` (default: `true`)
  - If `true` and `/hytale/Server/HytaleServer.aot` exists, adds `-XX:AOTCache=HytaleServer.aot`.

### Flags

- `ACCEPT_EARLY_PLUGINS` (default: `false`)
  - Adds `--accept-early-plugins`.
- `ALLOW_OP` (default: `false`)
  - Adds `--allow-op`.
- `DISABLE_SENTRY` (default: `false`)
  - Adds `--disable-sentry`.

### Backups

- `BACKUP_ENABLED` (default: `false`)
  - If `true`, adds backup arguments.
- `BACKUP_DIR` (default: `/hytale/backups`)
  - Backup output directory inside the container.
- `BACKUP_FREQUENCY` (default: `30`)
  - Backup frequency.

### Java memory

- `JAVA_XMS` (default: `4G`)
  - Adds `-Xms`.
- `JAVA_XMX` (default: `4G`)
  - Adds `-Xmx`.
- `JAVA_CMD_ADDITIONAL_OPTS` (optional)
  - Appends additional JVM args to the `java` command.

## Notes

- If the downloader fails with a `403 Forbidden`, the startup script clears `~/.hytale-downloader-credentials.json` and retries on next start.

## Docs

- Server Provider Authentication Guide: https://support.hytale.com/hc/en-us/articles/45328341414043-Server-Provider-Authentication-Guide
- Hytale Server Manual: https://support.hytale.com/hc/en-us/articles/45326769420827-Hytale-Server-Manual
