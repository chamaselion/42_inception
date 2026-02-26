FROM debian:bookworm

RUN apt-get update \
 && apt-get install -y \
    mariadb-server \
    mariadb-client

RUN mkdir -p /run/mysqld /var/lib/mysql && chown -R mysql:mysql /run/mysqld /var/lib/mysql && chmod 755 /run/mysqld
COPY tools/entrypoint.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/entrypoint.sh

VOLUME ["/var/lib/mysql"]
EXPOSE 3306

ENTRYPOINT [ "entrypoint.sh" ]