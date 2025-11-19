FROM alpine:3.18

LABEL description="Base image for the wordpress resource"


ENV WORDPRESS_CONF_DIR=/etc/wordpress
RUN mkdir -p "$WORDPRESS_CONF_DIR"

WORKDIR /usr/src/wordpress

COPY . .

