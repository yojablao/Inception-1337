#!/bin/bash
set -e

cd /var/www/html

wp user create "$WP_USER_LOGIN" "$WP_USER_MAIL" \
    --role=author \
    --user_pass="$WP_USER_PASS" \
    --allow-root


wp theme install "$THEME_SLUG" --activate --allow-root
wp plugin install "$PLUGIN_SLUG" --activate --allow-root

wp post delete 1 --force --allow-root
wp post delete 2 --force --allow-root
wp post delete 3 --force --allow-root

wp option update show_on_front 'posts' --allow-root

echo "Website build completed!"