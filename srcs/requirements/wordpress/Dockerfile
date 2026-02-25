FROM debian:bookworm

RUN apt update
RUN apt upgrade -y
RUN apt install -y php-fpm

COPY ./conf/www.conf /etc/php/8.2/fpm/pool.d/.

CMD ["php-fpm8.2", "-F"]
