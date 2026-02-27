.PHONY: all up down clear list hosts unhosts volumes_dirs

ENV_FILE	:= ./srcs/.env
COMPOSE_FILE	:= ./srcs/docker-compose.yml
HOSTS_FILE	:= /etc/hosts
LOOPBACK_IP	:= 127.0.0.1
DOMAIN_NAME	:= $(shell awk -F= '/^DOMAIN_NAME=/{print $$2}' $(ENV_FILE) | tr -d '\r')
DATA_ROOT	:= /home/bszikora/data
MARIADB_DIR	:= $(DATA_ROOT)/mariadb
WORDPRESS_DIR	:= $(DATA_ROOT)/wordpress

all: hosts volumes_dirs up

hosts:
	@if [ -z "$(DOMAIN_NAME)" ]; then \
		echo "DOMAIN_NAME is missing in $(ENV_FILE)"; \
		exit 1; \
	fi
	@echo "Ensuring hosts mapping for $(DOMAIN_NAME)..."
	@sudo sed -i '/[[:space:]]$(DOMAIN_NAME)\([[:space:]]\|$$\)/d' $(HOSTS_FILE)
	@sudo sed -i '/[[:space:]]www\.$(DOMAIN_NAME)\([[:space:]]\|$$\)/d' $(HOSTS_FILE)
	@echo "$(LOOPBACK_IP) $(DOMAIN_NAME) www.$(DOMAIN_NAME)" | sudo tee -a $(HOSTS_FILE) >/dev/null
	@echo "Mapped $(DOMAIN_NAME) and www.$(DOMAIN_NAME) to $(LOOPBACK_IP)"

unhosts:
	@if [ -z "$(DOMAIN_NAME)" ]; then \
		echo "DOMAIN_NAME is missing in $(ENV_FILE)"; \
		exit 1; \
	fi
	@sudo sed -i '/[[:space:]]$(DOMAIN_NAME)\([[:space:]]\|$$\)/d' $(HOSTS_FILE)
	@sudo sed -i '/[[:space:]]www\.$(DOMAIN_NAME)\([[:space:]]\|$$\)/d' $(HOSTS_FILE)
	@echo "Removed hosts mapping for $(DOMAIN_NAME) and www.$(DOMAIN_NAME)"

volumes_dirs:
	@echo "Ensuring volume directories under $(DATA_ROOT)..."
	@sudo mkdir -p "$(MARIADB_DIR)" "$(WORDPRESS_DIR)"
	@sudo chown -R "$(USER):$(USER)" "$(DATA_ROOT)"
	@echo "Volume directories ready: $(MARIADB_DIR), $(WORDPRESS_DIR)"

up:
	@docker compose --env-file $(ENV_FILE) -f $(COMPOSE_FILE) up -d --build

down:
	@docker compose --env-file $(ENV_FILE) -f $(COMPOSE_FILE) down

clear: down unhosts
	@docker compose --env-file $(ENV_FILE) -f $(COMPOSE_FILE) down --remove-orphans || true
	@docker container ls -aq | xargs -r docker rm -f
	@docker image ls -aq | xargs -r docker image rm -f
	@docker volume ls -q | xargs -r docker volume rm
	@docker network ls --filter type=custom -q | xargs -r docker network rm || true
	@sudo rm -rf "$(DATA_ROOT)"
	@echo "Removed host volume directories under $(DATA_ROOT)"

list:
	@printf "\nDocker networks:\n"
	@docker network ls
	@printf "\nDocker containers:\n"
	@docker container ls -a
	@printf "\nDocker images:\n"
	@docker image ls
	@printf "\nDocker volumes:\n"
	@docker volume ls