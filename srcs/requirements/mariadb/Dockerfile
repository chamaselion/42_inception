FROM debian:bookworm


RUN apt update
RUN apt upgrade -y
RUN apt install -y mariadb-server

COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/.
COPY tools/init.sql /etc/mysql/init.sql

RUN mkdir /run/mysqld

CMD ["mysqld"]
