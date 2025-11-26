#!/bin/bash
set -e
sleep 20

validate_admin_username() {
    local username="${1,,}"

    if [[ "$username" == *admin* || "$username" == *administrator* ]]; then
        cat <<EOF
ERROR: Administrator username '${1}' contains forbidden patterns.
EOF
        return 1
    fi
    return 0
}


echo "Waiting for database to be ready..."

echo "Setting up WordPress directory..." 
mkdir -p /var/www/html
cd /var/www/html

if [ ! -f "/var/www/html/wp-config.php" ]; then
	if ! validate_admin_username "$WP_ADMIN_LOGIN"; then
        echo "Installation aborted due to invalid administrator username."
        exit 1
    fi
    echo "Fetching WordPress CLI..."
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x wp-cli.phar
    mv wp-cli.phar /usr/local/bin/wp
    echo "WP-CLI installed successfully"
    wp core download --force --allow-root --quiet

    echo "Setting up WordPress configuration..."
    wp config create --allow-root \
        --dbname=$DB_NAME \
        --dbuser=$DB_USERNAME \
        --dbpass=$DB_USER_PASS \
        --dbhost=$DB_HOSTNAME \
        --force

    echo "Installing WordPress site..."
    wp core install --allow-root \
        --url=$WP_URL \
        --title=$WP_TITLE \
        --admin_user=$WP_ADMIN_LOGIN \
        --admin_password=$WP_ADMIN_PASS \
        --admin_email=$WP_ADMIN_MAIL \
        --skip-email

    echo "Setting up author user..."
    wp user create "$WP_USER_LOGIN" "$WP_USER_MAIL" \
        --role=author \
        --user_pass="$WP_USER_PASS" \
        --allow-root
fi

chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

sed -i 's/^listen = .*/listen = 0.0.0.0:9000/' /etc/php/8.2/fpm/pool.d/www.conf

echo "WordPress setup completed successfully!"
echo "Administrator user: $WP_ADMIN_LOGIN"
echo "Author user: $WP_USER_LOGIN"

touch /var/www/html/.wp_installed

echo "Starting PHP-FPM in foreground mode..."
exec /usr/sbin/php-fpm8.2 -F
    
