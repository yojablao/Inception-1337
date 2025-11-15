
#!/bin/bash

# Create the main project directory structure for Inception
mkdir -p srcs/{secrets,requirements/{mariadb,nginx,wordpress,bonus,tools}}

# Create subdirectories for each service
mkdir -p srcs/requirements/mariadb/{conf,tools}
mkdir -p srcs/requirements/nginx/{conf,tools}
mkdir -p srcs/requirements/wordpress/{conf,tools}
mkdir -p srcs/requirements/bonus/{redis,ftp,adminer,static-site,custom-service}

# Create the main configuration files
touch Makefile
touch srcs/docker-compose.yml
touch srcs/.env
touch srcs/.dockerignore

# Create Dockerfiles for each service
touch srcs/requirements/mariadb/Dockerfile
touch srcs/requirements/mariadb/.dockerignore
touch srcs/requirements/nginx/Dockerfile
touch srcs/requirements/nginx/.dockerignore
touch srcs/requirements/wordpress/Dockerfile
touch srcs/requirements/wordpress/.dockerignore

# Create configuration directories and files
touch srcs/requirements/mariadb/conf/my.cnf
touch srcs/requirements/nginx/conf/nginx.conf
touch srcs/requirements/nginx/conf/ssl.conf
touch srcs/requirements/wordpress/conf/www.conf

# Create secret files
touch srcs/secrets/db_password.txt
touch srcs/secrets/db_root_password.txt
touch srcs/secrets/credentials.txt

# Create tool scripts (for initialization, health checks, etc.)
touch srcs/requirements/mariadb/tools/init.sql
touch srcs/requirements/mariadb/tools/healthcheck.sh
touch srcs/requirements/nginx/tools/healthcheck.sh
touch srcs/requirements/wordpress/tools/healthcheck.sh
touch srcs/requirements/wordpress/tools/wp-config.php

# Create bonus service Dockerfiles
touch srcs/requirements/bonus/redis/Dockerfile
touch srcs/requirements/bonus/ftp/Dockerfile
touch srcs/requirements/bonus/adminer/Dockerfile
touch srcs/requirements/bonus/static-site/Dockerfile
touch srcs/requirements/bonus/custom-service/Dockerfile

# Set proper permissions for secret files
chmod 600 srcs/secrets/*.txt

echo "File structure created successfully!"
echo ""
echo "Directory structure:"
find . -type d | sort