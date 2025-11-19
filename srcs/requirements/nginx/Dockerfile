FROM alpine:3.18

LABEL description="Base image for the nginx resource"

RUN apk update && apk upgrade --no-cache


ENV NGINX_CONF_DIR=/etc/nginx
RUN mkdir -p "$NGINX_CONF_DIR"

WORKDIR /usr/src/nginx

# COPY . .
