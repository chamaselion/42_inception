# USER_DOC

## Provided services
This stack provides:
- HTTPS website endpoint through NGINX on port 443
- WordPress application running with PHP-FPM
- MariaDB database for WordPress data

## Start and stop
From repository root:

```bash
make
```
Starts and builds the stack.

```bash
make down
```
Stops the running stack.

## Access website and admin panel
- Website: `https://bszikora.42.fr`
- WordPress admin panel: `https://bszikora.42.fr/wp-admin`

By default, `make` will update the VM's `/etc/hosts` to map `DOMAIN_NAME` to `127.0.0.1`.
If you want to access the website from outside the VM, add a hosts/DNS entry on your host machine pointing `DOMAIN_NAME` to the VM IP.

## Ports
Ports are defined in `srcs/.env`:
- `NGINX_PORT` must stay `443` (subject requirement: only entrypoint is HTTPS on 443)
- `WP_PHP_PORT` is the internal WordPress PHP-FPM port
- `MARIADB_PORT` is the internal MariaDB port

## Credentials location and management
- Runtime variables are loaded from `srcs/.env`.
- Replace placeholder values with local credentials before running.
- Do not commit real credentials to Git.
- Rotate credentials by updating local env values and recreating containers.

## Health checks and status verification
Check service status:

```bash
docker compose -f srcs/docker-compose.yml ps
```

View logs:

```bash
docker compose -f srcs/docker-compose.yml logs --tail=100
```

Confirm HTTPS endpoint:

```bash
curl -kI https://bszikora.42.fr
```
