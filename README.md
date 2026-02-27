*This project has been created as part of the 42 curriculum by bszikora.*

## Description
Inception builds a small containerized infrastructure using Docker Compose. The mandatory stack contains three isolated services:
- NGINX as the only public entrypoint on HTTPS (port 443)
- WordPress with PHP-FPM (without NGINX)
- MariaDB (without NGINX)

The goal is to provide a secure, reproducible local deployment with persistent data and clear service boundaries.

## Project Design
### Docker in this project
Docker is used to package each service with its own runtime dependencies and startup logic. Docker Compose orchestrates networking, storage, startup order, and restart behavior.

### Included sources
- `srcs/docker-compose.yml`: service orchestration, network, and volumes
- `srcs/requirements/mariadb`: MariaDB image and entrypoint
- `srcs/requirements/wordpress`: WordPress + PHP-FPM image and entrypoint
- `srcs/requirements/nginx`: NGINX + TLS image and entrypoint
- `Makefile`: build/start/stop convenience targets

### Main design choices
- One Dockerfile per mandatory service
- One dedicated container per service
- Internal bridge network for inter-service communication
- NGINX only on external port 443
- Named volumes for persistent WordPress and database data
- Environment-variable based runtime configuration

### Comparisons
#### Virtual Machines vs Docker
- Virtual Machines emulate full operating systems with their own kernel-level isolation overhead.
- Docker containers share the host kernel and are lighter and faster to build, start, and rebuild.
- For this project, Docker gives repeatability and speed while keeping service isolation.

#### Secrets vs Environment Variables
- Environment variables are simple and required by the project for configuration wiring.
- Docker secrets are better for sensitive values because they avoid exposing credentials in plain text in repository files.
- For production-like security, secrets should hold real passwords while env vars hold non-sensitive settings.

#### Docker Network vs Host Network
- Docker bridge network isolates services and gives controlled connectivity by service name.
- Host networking removes that isolation and is forbidden by the subject rules for this mandatory setup.
- This stack uses a dedicated Compose network to keep traffic scoped and predictable.

#### Docker Volumes vs Bind Mounts
- Docker named volumes are managed by Docker and are portable and less error-prone for persistence.
- Bind mounts directly map host paths and are more coupled to host filesystem layout.
- This project persists WordPress and MariaDB data through named volumes.

## Instructions
### Prerequisites
- Linux VM
- Docker Engine + Docker Compose plugin
- DNS/hosts mapping for `bszikora.42.fr` to your VM IP

### Build and run
From repository root:

```bash
make
```

### Stop
```bash
make down
```

### Clean (dangerous)
```bash
make clear
```

### Verify running services
```bash
docker compose -f srcs/docker-compose.yml ps
```

## Resources
- Docker docs: https://docs.docker.com/
- Docker Compose docs: https://docs.docker.com/compose/
- NGINX docs: https://nginx.org/en/docs/
- MariaDB docs: https://mariadb.com/kb/en/documentation/
- WordPress CLI docs: https://developer.wordpress.org/cli/commands/
- PHP-FPM docs: https://www.php.net/manual/en/install.fpm.php

### AI usage disclosure
AI was used for:
- Reviewing subject compliance against project files
- Identifying strict-rule mismatches in Compose and tracked credentials
- Drafting documentation structure and checklists

All generated suggestions were manually reviewed and adapted before use.