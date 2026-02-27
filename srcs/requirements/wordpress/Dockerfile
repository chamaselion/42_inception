FROM debian:bookworm

RUN apt update && apt upgrade -y \
 && apt install -y curl mariadb-client imagemagick openssl \
    php php-fpm php-mysql php-curl php-xml php-intl php-mbstring php-zip php-imagick \
 && ln -sf /bin/true /usr/sbin/sendmail \
 && rm -rf /var/lib/apt/lists/*
RUN getent group nginx >/dev/null 2>&1 || groupadd -r nginx
RUN id -u nginx >/dev/null 2>&1 || useradd -r -g nginx -M -s /usr/sbin/nologin nginx


RUN cd /usr/local/bin && curl -o wp -L https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && chmod +x wp
COPY tools/wordpress-entrypoint.sh /usr/local/bin
RUN chmod +x /usr/local/bin/wordpress-entrypoint.sh

ENTRYPOINT [ "wordpress-entrypoint.sh" ]