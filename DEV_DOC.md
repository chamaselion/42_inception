# DEV_DOC

## Environment setup from scratch
### Prerequisites
- Linux virtual machine
- Docker Engine and Docker Compose plugin installed
- User has permission to run Docker commands

### Configuration
- Edit `srcs/.env` and set local non-committed credential values.
- Ensure `DOMAIN_NAME` resolves inside the VM. The default `make` target updates `/etc/hosts` to map it to `127.0.0.1`.

### Optional local secret handling
- Keep real secret material in local files (for example in `secrets/`) excluded from Git.
- Never store production credentials in tracked repository files.

## Build and launch workflow
From repository root:

```bash
make
```
This runs Docker Compose build and startup using `srcs/docker-compose.yml`.

Stop the stack:

```bash
make down
```

Destroy stack artifacts (use carefully):

```bash
make clear
```

## Container and volume management commands
List compose resources:

```bash
docker compose -f srcs/docker-compose.yml ps
```

Inspect logs:

```bash
docker compose -f srcs/docker-compose.yml logs -f
```

Inspect volumes:

```bash
docker volume ls
docker volume inspect mariadb
docker volume inspect wordpress
```

## Data persistence
Persistent data is stored in Docker named volumes:
- `mariadb` for `/var/lib/mysql`
- `wordpress` for `/var/www/html`

On the host, the volume data is stored under `/home/bszikora/data/` (created by the `make volumes_dirs` target).
Data survives container recreation as long as volumes are not removed.

## Ports
Ports are configured through `srcs/.env` and wired into Compose + entrypoints:
- `NGINX_PORT` (public) — keep `443` for subject compliance
- `WP_PHP_PORT` (internal PHP-FPM)
- `MARIADB_PORT` (internal MariaDB)

## Project layout
- `Makefile`: entry targets for build/start/stop/cleanup
- `srcs/docker-compose.yml`: orchestration and policies
- `srcs/requirements/mariadb`: DB image and startup
- `srcs/requirements/wordpress`: app image and startup
- `srcs/requirements/nginx`: TLS reverse-proxy image and startup
