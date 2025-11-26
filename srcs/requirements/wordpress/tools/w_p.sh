#!/bin/bash
set -e
sleep 20





mkdir -p /var/www/html
cd /var/www/html

if [ ! -f "/var/www/html/wp-config.php" ]; then
ADMIN_LOWERCASE="${WP_USER_LOGIN,,}"
    if [ "$ADMIN_LOWERCASE" = "admin" ]; then
        echo "FATAL: Administrator username '$WP_USER_LOGIN' is forbidden." >&2
        exit 1
    fi
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x wp-cli.phar
    mv wp-cli.phar /usr/local/bin/wp
    wp core download --force --allow-root --quiet

    wp config create --allow-root \
        --dbname=$DB_NAME \
        --dbuser=$DB_USERNAME \
        --dbpass=$DB_USER_PASS \
        --dbhost=$DB_HOSTNAME \
        --force

    wp core install --allow-root \
        --url=$WP_URL \
        --title=$WP_TITLE \
        --admin_user=$WP_ADMIN_LOGIN \
        --admin_password=$WP_ADMIN_PASS \
        --admin_email=$WP_ADMIN_MAIL \
        --skip-email

    wp user create "$WP_USER_LOGIN" "$WP_USER_MAIL" \
        --role=author \
        --user_pass="$WP_USER_PASS" \
        --allow-root
    /makeit.sh
fi

chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

sed -i 's/^listen = .*/listen = 0.0.0.0:9000/' /etc/php/8.2/fpm/pool.d/www.conf
touch /var/www/html/.wp_installed
exec /usr/sbin/php-fpm8.2 -F
    
