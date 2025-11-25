FROM debian:bookworm

RUN apt-get update && apt-get install -y \
    php \
    php-fpm \
    curl \
    php-mysql \
    netcat-traditional\
    mariadb-client

COPY ./tools/w_p.sh/ .

RUN chmod +x /w_p.sh

EXPOSE 9000

WORKDIR /var/www/html

CMD ["bash", "/w_p.sh"]