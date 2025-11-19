.PHONY: all up down clear list

all: up

up:
	@docker compose -f ./srcs/docker-compose.yml up -d --build

down:
	@docker compose -f ./srcs/docker-compose.yml down

clear:
	@docker compose -f ./srcs/docker-compose.yml down --remove-orphans || true
	@docker container ls -aq | xargs -r docker rm -f
	@docker image ls -aq | xargs -r docker image rm -f
	@docker volume ls -q | xargs -r docker volume rm
	@docker network ls -q | xargs -r docker network rm

list:
	@printf "\nDocker networks:\n"
	@docker network ls
	@printf "\nDocker containers:\n"
	@docker container ls -a
	@printf "\nDocker images:\n"
	@docker image ls
	@printf "\nDocker volumes:\n"
	@docker volume ls