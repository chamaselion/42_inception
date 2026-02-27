FROM debian:bookworm

RUN apt update
RUN apt upgrade -y
RUN apt install -y nginx openssl ca-certificates

RUN groupadd -g 101 nginx 2>/dev/null || true && useradd -u 100 -r -g nginx -M -s /usr/sbin/nologin nginx 2>/dev/null || true


RUN mkdir -p /etc/nginx/ssl

RUN mkdir -p /etc/nginx/ssl
RUN mkdir -p /etc/nginx/http.d

COPY ./tools/entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]

