#!/bin/bash
set -e

echo "=== Starting MariaDB Setup ==="

service mariadb start
sleep 5

echo "Creating database and user..."
mariadb -h localhost -e "CREATE DATABASE IF NOT EXISTS $MYSQL_DATABASE;"
mariadb -h localhost -e "CREATE USER IF NOT EXISTS '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';"
mariadb -h localhost -e "GRANT ALL PRIVILEGES ON $MYSQL_DATABASE.* TO '$MYSQL_USER'@'%';"
mariadb -h localhost -e "FLUSH PRIVILEGES;"

echo "Database setup completed"
mariadb-admin -p"$MYSQL_ROOT_PASSWORD" shutdown
exec mysqld_safe --bind-address=0.0.0.0
