FROM debian:bookworm

RUN apt-get update && apt-get install -y \
    php \
    php-fpm \
    curl \
    php-mysql \
    netcat-traditional\
    mariadb-client

WORKDIR /var/www/html
COPY ./tools/w_p.sh/ /w_p.sh

RUN chmod +x /w_p.sh

# EXPOSE 9000


CMD  ["/w_p.sh"]