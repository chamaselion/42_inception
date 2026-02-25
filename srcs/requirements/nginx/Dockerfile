FROM debian:bookworm

RUN apt update
RUN apt upgrade -y
RUN apt install -y nginx

COPY ./conf/default /etc/nginx/sites-available/.

CMD ["nginx", "-g", "daemon off;"]