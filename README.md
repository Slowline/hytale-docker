Hytale dedicated server in Docker. The container supports automatic updates on the server startup via the official Hytale Downloader CLI and runs `HytaleServer.jar` with custom launch options based on environment

## Quick start

Copy `.env.example` to `.env` and edit as needed.
On linux can be done via:
```bash
cp .env.example .env
```

Start the server with `docker compose up -d` or `make up`

Follow logs with `docker compose logs -f` or `make logs`

## Authentication

Attach to the running container and authenticate using the server console:

```bash
docker attach hytale
auth login device
```

To persist authentication across restarts, enable machine ID access in `docker-compose.yml` and run:

```bash
auth persistence Encrypted
```

## Compose setup

`docker-compose.yml` uses:

- Container name `hytale`
- UDP port `5520`
- Named volume `hytale-data` mounted at `/hytale`
- `.env` file for configuration

## Makefile helpers

The Makefile wraps common `docker compose` commands:

`build`, `up`, `down`, `restart`, `status`, `logs`, `in`, `attach`, `update`, `update-hytale-downloader`

Run `make` for descriptions

## Environment variables

Defaults are defined in [Dockerfile](Dockerfile) and [.env.example](.env.example) and can be overridden in your `.env` file

### Server and networking

- `HYTALE_PORT` (default `5520`): UDP port to listen on
- `BIND_ADDR` (default `0.0.0.0`): bind address

### Assets and auth mode

- `ASSETS_PATH` (default `/hytale/Assets.zip`): assets zip path in the container
- `AUTH_MODE` (default `authenticated`): `authenticated`, `offline`, or `insecure`

Optional server provider tokens (only passed when set in `.env.` file):

- `SESSION_TOKEN`: adds `--session-token`
- `IDENTITY_TOKEN`: adds `--identity-token`
- `OWNER_UUID`: adds `--owner-uuid`

### Updates

- `ENABLE_AUTO_UPDATE` (default `true`): download and update the server on container start
- `SKIP_DELETE_ON_FORBIDDEN` (default `false`): keep downloader credentials on `403 Forbidden`

The downloader binary also checks for its own updates on every start.

### JVM and server flags

- `JAVA_XMS` (default `4G`): initial heap size
- `JAVA_XMX` (default `4G`): max heap size
- `JAVA_CMD_ADDITIONAL_OPTS`: extra JVM options appended to `java`
- `USE_AOT_CACHE` (default `true`): add `-XX:AOTCache=HytaleServer.aot` if present
- `ACCEPT_EARLY_PLUGINS` (default `false`): add `--accept-early-plugins`
- `ALLOW_OP` (default `false`): add `--allow-op`
- `DISABLE_SENTRY` (default `false`): add `--disable-sentry`
- `HYTALE_ADDITIONAL_OPTS`: additional server options appended at the end

### Backups

- `BACKUP_ENABLED` (default `false`): enable backups
- `BACKUP_DIR` (default `/hytale/backups`): backup output directory
- `BACKUP_FREQUENCY` (default `30`): minutes between backups

## Notes

- If the downloader fails with `403 Forbidden`, the startup script may remove `~/.hytale-downloader-credentials.json` unless `SKIP_DELETE_ON_FORBIDDEN=true`.
- The server data lives in the `hytale-data` volume at `/hytale`.

## Links

- Server Provider Authentication Guide: https://support.hytale.com/hc/en-us/articles/45328341414043-Server-Provider-Authentication-Guide
- Hytale Server Manual: https://support.hytale.com/hc/en-us/articles/45326769420827-Hytale-Server-Manual
