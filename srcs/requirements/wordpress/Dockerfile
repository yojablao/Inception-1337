FROM debian:bookworm

RUN apt-get update && apt-get install -y

RUN apt-get install -y   php \
    php-fpm \
    curl \
    php-mysql \
    mariadb-client

WORKDIR /var/www/html
COPY ./tools/w_p.sh/ /w_p.sh



RUN chmod +x /w_p.sh 



CMD  ["/w_p.sh"]