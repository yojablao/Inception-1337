FROM debian:bookworm

RUN apt-get update && apt-get install -y

RUN apt-get install -y   php \
    php-fpm \
    curl \
    php-mysql \
    mariadb-client

WORKDIR /var/www/html
COPY ./tools/w_p.sh/ /w_p.sh
COPY ./tools/makeit.sh makeit.sh


RUN chmod +x /w_p.sh makeit.sh



CMD  ["/w_p.sh"]