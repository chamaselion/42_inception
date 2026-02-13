FROM alpine:3.18

LABEL description="Nginx with TLS 1.2/1.3"

RUN apk update && apk upgrade --no-cache \
	&& apk add --no-cache nginx openssl ca-certificates \
	&& mkdir -p /run/nginx /etc/nginx/conf.d

ENV NGINX_CONF_DIR=/etc/nginx
WORKDIR /usr/src/nginx

# Copy configuration and tooling
COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY tools/generate_cert.sh tools/entrypoint.sh /usr/src/nginx/tools/

RUN chmod +x /usr/src/nginx/tools/*.sh

EXPOSE 443

ENTRYPOINT ["/usr/src/nginx/tools/entrypoint.sh"]
