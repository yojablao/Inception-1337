# Docker Inception Project - Complete Q&A Guide

## Part 1: Docker Fundamentals

### Q1: What is a container and how does it differ from a virtual machine?

**Answer:**
A container is a lightweight, standalone executable package that includes everything needed to run a piece of software: code, runtime, system tools, libraries, and settings.

**Key Differences:**
- **Containers** share the host OS kernel and isolate the application processes from the rest of the system
- **Virtual Machines** include a full copy of an operating system, a virtual copy of the hardware, and run on a hypervisor

**Why Containers Are More Efficient:**
- Containers start in seconds vs minutes for VMs
- Containers use MBs of space vs GBs for VMs
- Multiple containers can run on the same machine and share the OS kernel
- Less overhead means better resource utilization

### Q2: What is a Docker image and how is it built?

**Answer:**
A Docker image is a read-only template containing instructions for creating a container. It's built from a Dockerfile.

**Build Process:**
1. **Instruction Execution**: Each line in the Dockerfile (FROM, RUN, COPY, etc.) is executed sequentially
2. **Layer Creation**: Each instruction creates a new read-only layer
3. **Layer Stacking**: Layers stack on top of each other to form the complete image
4. **Caching**: Docker caches layers, so unchanged layers are reused in subsequent builds

**Example from your project:**
```dockerfile
FROM debian:bookworm          # Layer 1: Base OS
RUN apt update && apt install # Layer 2: Package installation
COPY ./tools/m_db.sh .        # Layer 3: Copy files
```

### Q3: What is the Union File System and why is it important for Docker?

**Answer:**
Union File System (UFS) creates an illusion of merging multiple directories into one without modifying the originals.

**Key Features:**

1. **Layered Approach*
1. **Layered Approach*: Directories stack on top of each other with priority order
2. **Copy-on-Write (CoW)**: Lower layers are read-only; when you modify a file, it's copied to the writable top layer
3. **Whiteouts**: Special files that hide deleted files in lower layers without actually deleting them

**Popular Implementations:**
- **UnionFS**: Original (deprecated)
- **AUFS**: Improved version, used in older Docker
- **OverlayFS**: Modern standard (Linux kernel 3.18+), default in modern Docker
- **ZFS, Btrfs**: Alternative filesystems

**Why It Matters:**
- **Space Efficiency**: Images share common layers
- **Fast Container Startup**: No need to copy entire filesystem
- **Isolation**: Each container has its own writable layer

### Q4: How does a container's filesystem work at runtime?

**Answer:**
When you run `docker run <image>`, Docker creates a union mount with:

1. **Lower Directories (lowerdir)**: All read-only image layers stacked
2. **Upper Directory (upperdir)**: New empty read-write container layer
3. **Merged View**: Combined view presented as the container's root filesystem (/)
4. **Work Directory**: Temporary storage for OverlayFS operations

**Visual Representation:**
```
Container View (/)
       ↓
   [Merged]
       ↓
  [upperdir] ← Read-Write Container Layer
       +
  [lowerdir] ← Read-Only Image Layers
```

## Part 2: Docker Compose & Networking

### Q5: What is Docker Compose and why use it?

**Answer:**
Docker Compose is a tool for defining and running multi-container Docker applications using a YAML file.

**Benefits:**
- Define entire application stack in one file
- Easy service orchestration with dependencies
- Environment variable management
- Volume and network configuration
- One-command deployment (`docker compose up`)

**Your Project Structure:**
```yaml
services:
  mariadb:    # Database service
  wordpress:  # Application service
  nginx:      # Web server/reverse proxy
networks:     # Custom network
volumes:      # Persistent storage
```

### Q6: What are Docker networks and how do they work?

**Answer:**
Docker networks allow containers to communicate with each other and the outside world.

**Network Drivers:**
1. **Bridge** (default): Private network on host, containers can talk to each other
2. **Host**: Container uses host's network directly
3. **None**: No networking
4. **Overlay**: Multi-host networking for Swarm

**Your Project Network:**
```yaml
networks:
  inception:
    name: inception
    driver: bridge
```

**How It Works:**
- All three services (nginx, wordpress, mariadb) are on the same `inception` network
- They can reference each other by service name (DNS resolution)
- Example: `fastcgi_pass wordpress:9000` - nginx connects to wordpress by name

### Q7: How do containers communicate in your project?

**Answer:**
**Communication Flow:**
```
Client (Browser)
    ↓ HTTPS (443)
  [nginx]
    ↓ FastCGI (9000)
  [wordpress]
    ↓ MySQL (3306)
  [mariadb]
```

**Key Points:**
- **nginx** exposes port 443 to host (`ports: - 443:443`)
- **wordpress** and **mariadb** are only accessible within the network
- Services use internal Docker DNS to resolve service names
- No direct external access to wordpress or mariadb (security)

## Part 3: Volumes & Persistence

### Q8: What are Docker volumes and why are they needed?

**Answer:**
Volumes are the preferred mechanism for persisting data generated by and used by Docker containers.

**Types:**
1. **Named Volumes**: Managed by Docker (`docker volume create`)
2. **Bind Mounts**: Direct mapping to host filesystem path
3. **tmpfs Mounts**: Stored in host memory only

**Your Project Volumes:**
```yaml
volumes:
  wordpress:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/yojablao/data/wordpress

  mariadb:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/yojablao/data/mariadb
```

**Why Bind Mounts Here:**
- Data persists even if containers are removed
- Easy backup and inspection from host
- Meets project requirements for specific host paths

### Q9: What happens to data when containers are destroyed?

**Answer:**
**Without Volumes:**
- All data in container's writable layer is lost
- Every `docker compose down` = fresh start

**With Volumes:**
- Data persists on the host filesystem
- Database contents survive container recreation
- WordPress files (themes, plugins, uploads) are preserved

**Your Project:**
- MariaDB data → `/home/yojablao/data/mariadb`
- WordPress files → `/home/yojablao/data/wordpress`

## Part 4: Services Deep Dive

### Q10: How does the MariaDB container work?

**Answer:**
**Dockerfile Analysis:**
```dockerfile
FROM debian:bookworm                           # Base image
RUN apt update && apt upgrade -y && \
    apt install mariadb-server netcat-traditional -y  # Install MariaDB
COPY ./tools/m_db.sh .                        # Copy setup script
RUN chmod +x ./m_db.sh                        # Make executable
ENTRYPOINT ["./m_db.sh"]                      # Run on container start
```

**Startup Script (m_db.sh):**
```bash
service mariadb start              # Start MariaDB temporarily
sleep 5                            # Wait for it to be ready

# Create database and user
mariadb -e "CREATE DATABASE IF NOT EXISTS $MYSQL_DATABASE;"
mariadb -e "CREATE USER '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';"
mariadb -e "GRANT ALL PRIVILEGES ON $MYSQL_DATABASE.* TO '$MYSQL_USER'@'%';"
mariadb -e "FLUSH PRIVILEGES;"

mariadb-admin shutdown             # Stop temporary instance
exec mariadbd-safe --bind-address=0.0.0.0  # Run as PID 1
```

**Why This Approach:**
- Database initialization happens on first run
- `exec` replaces shell with mariadbd-safe (proper PID 1)
- `--bind-address=0.0.0.0` allows network connections
- Data persists in `/var/lib/mysql` (mounted volume)

### Q11: What is a healthcheck and why is it important?

**Answer:**
A healthcheck determines if a container is functioning properly.

**Your MariaDB Healthcheck:**
```yaml
healthcheck:
  test: ["CMD", "nc", "-z", "localhost", "3306"]  # Check if port 3306 is open
  interval: 10s        # Check every 10 seconds
  timeout: 5s          # Fail if check takes >5s
  retries: 20          # Try 20 times before marking unhealthy
  start_period: 60s    # Grace period for startup
```

**Why It Matters:**
- WordPress depends on MariaDB being healthy
- Prevents WordPress from starting before database is ready
- `depends_on: mariadb: condition: service_healthy`

### Q12: How does the WordPress container work?

**Answer:**
**Dockerfile:**
```dockerfile
FROM debian:bookworm
RUN apt install php php-mysql curl php-fpm netcat-traditional -y
COPY ./tools/w_p.sh .
RUN chmod +x ./w_p.sh
ENTRYPOINT ["./w_p.sh"]
```

**Startup Script (w_p.sh):**
```bash
# 1. Install WP-CLI (WordPress Command Line)
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
mv wp-cli.phar /bin/wp

cd /var/www/html

# 2. Download WordPress core files
wp core download --allow-root

# 3. Create wp-config.php with database credentials
wp config create --dbname=$MYSQL_DATABASE --dbuser=$MYSQL_USER \
  --dbpass=$MYSQL_PASSWORD --dbhost=$MYSQL_HOST --allow-root

# 4. Install WordPress (creates tables, admin user)
wp core install --url="$DOMAIN_NAME" --title=$WP_TITLE \
  --admin_user=$WP_ADMIN_USER --admin_password=$WP_ADMIN_PASSWORD \
  --admin_email=$WP_ADMIN_EMAIL --skip-email --allow-root

# 5. Create additional user
wp user create $WP_USER $WP_USER_EMAIL --user_pass=$WP_USER_PASSWORD \
  --role=$WP_USER_ROLE --allow-root

# 6. Set proper permissions
chown -R www-data:www-data .
chmod -R 775 .

# 7. Configure PHP-FPM to listen on network port
sed -i 's#listen = /run/php/php8.2-fpm.sock#listen = 0.0.0.0:9000#' \
  /etc/php/8.2/fpm/pool.d/www.conf

# 8. Start PHP-FPM in foreground
exec php-fpm8.2 -F
```

**Key Concepts:**
- **WP-CLI**: Command-line tool for WordPress management
- **PHP-FPM**: FastCGI Process Manager for PHP
- **Port 9000**: PHP-FPM listens here for FastCGI requests from nginx

### Q13: What is FastCGI and how does it work?

**Answer:**
**FastCGI (Fast Common Gateway Interface)** is a protocol for interfacing web servers with application servers.

**Traditional CGI Problems:**
- Creates new process for each request
- Very slow and resource-intensive
- Process startup overhead

**FastCGI Solution:**
- Long-running processes
- Handles multiple requests per process
- Much faster and more efficient

**In Your Project:**
```nginx
location ~ \.php$ {
    fastcgi_pass wordpress:9000;              # Send to PHP-FPM
    fastcgi_index index.php;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    include fastcgi_params;
}
```

**Flow:**
1. Client requests `example.com/index.php`
2. Nginx receives request on port 443
3. Nginx forwards to wordpress:9000 via FastCGI protocol
4. PHP-FPM executes PHP code
5. Returns result to nginx
6. Nginx sends to client

### Q14: How does the Nginx container work?

**Answer:**
**Dockerfile:**
```dockerfile
FROM debian:bullseye
RUN apt install nginx openssl -y

# Create SSL certificate
RUN mkdir -p /etc/nginx/ssl
RUN openssl req -x509 -nodes -days 180 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/server_ca.key \
    -out /etc/nginx/ssl/server_ca.crt \
    -subj "/C=MA/ST=Khnifra-beniMellal/L=Khouribga/O=1337/OU=IT/CN=yojablao.42.fr"

RUN chmod 600 /etc/nginx/ssl/server_ca.key  # Private key - restricted
RUN chmod 644 /etc/nginx/ssl/server_ca.crt  # Certificate - readable

COPY ./conf/nginx.conf /etc/nginx/nginx.conf
ENTRYPOINT ["nginx", "-g", "daemon off;"]
```

**Nginx Configuration:**
```nginx
events {
    worker_connections 1024;  # Max concurrent connections per worker
}

http {
    include /etc/nginx/mime.types;  # File type definitions

    server {
        listen 443 ssl;              # HTTPS port
        server_name yojablao.42.fr;   # Domain name

        ssl_certificate /etc/nginx/ssl/server_ca.crt;      # Public cert
        ssl_certificate_key /etc/nginx/ssl/server_ca.key;  # Private key
        ssl_protocols TLSv1.2 TLSv1.3;                    # Secure protocols only

        root /var/www/html;          # WordPress files location
        index index.php index.html;  # Default files

        location ~ \.php$ {          # PHP file handling
            fastcgi_pass wordpress:9000;  # Forward to PHP-FPM
            fastcgi_index index.php;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            include fastcgi_params;
        }
    }
}
```

**Key Points:**
- Acts as reverse proxy
- Handles HTTPS/SSL
- Serves static files directly
- Forwards PHP requests to wordpress container

## Part 5: Security & HTTPS

### Q15: What is HTTPS and how does TLS/SSL work?

**Answer:**
**HTTPS = HTTP + TLS/SSL encryption**

**TLS Handshake Process:**
1. **Client Hello**: Client sends supported cipher suites and TLS version
2. **Server Hello**: Server chooses cipher suite, sends certificate
3. **Certificate Verification**: Client verifies certificate with CA
4. **Key Exchange**: Both parties establish shared secret key
5. **Encrypted Communication**: All data encrypted with symmetric key

**In Your Project:**
```bash
openssl req -x509 -nodes -days 180 -newkey rsa:2048 \
    -keyout server_ca.key -out server_ca.crt \
    -subj "/C=MA/.../CN=yojablao.42.fr"
```

**Parameters Explained:**
- `-x509`: Create self-signed certificate
- `-nodes`: No passphrase for private key
- `-days 180`: Certificate valid for 180 days
- `-newkey rsa:2048`: Create new 2048-bit RSA key
- `-keyout`: Private key filename
- `-out`: Certificate filename
- `-subj`: Certificate subject information

**Self-Signed vs CA-Signed:**
- **Self-signed**: Created and signed by you (browsers show warning)
- **CA-signed**: Signed by trusted Certificate Authority (browsers trust)
- Your project uses self-signed (OK for development/internal use)

### Q16: Why use TLSv1.2 and TLSv1.3 only?

**Answer:**
**Deprecated Protocols:**
- **SSLv2/SSLv3**: Severely compromised, broken cryptography
- **TLSv1.0/TLSv1.1**: Vulnerable to attacks like BEAST, POODLE

**Modern Protocols:**
- **TLSv1.2**: Industry standard, secure with proper configuration
- **TLSv1.3**: Latest version, faster handshake, stronger security

**Your Configuration:**
```nginx
ssl_protocols TLSv1.2 TLSv1.3;
```

This ensures only secure protocol versions are accepted.

## Part 6: Process Management

### Q17: What is PID 1 and why does it matter in Docker?

**Answer:**
**PID 1** is the first process started in a system (or container). It has special responsibilities:

**In Linux:**
- Init system (systemd, init)
- Reaps zombie processes
- Handles signals (SIGTERM, SIGINT)
- Manages child processes

**In Docker:**
- Container lives as long as PID 1 is running
- When PID 1 exits, container stops
- PID 1 should handle signals properly for graceful shutdown

**Bad Example:**
```dockerfile
ENTRYPOINT ["./script.sh"]
```
If script.sh runs something with `./program &`, the shell is PID 1, not the program.

**Good Example:**
```dockerfile
ENTRYPOINT ["./script.sh"]
```
```bash
# In script.sh
exec mariadbd-safe  # Replace shell with mariadbd-safe
```

**Why `exec`:**
- Replaces current process (shell) with new process
- New process becomes PID 1
- Receives signals directly
- Proper container lifecycle management

### Q18: What does `daemon off;` mean in nginx?

**Answer:**
```nginx
ENTRYPOINT ["nginx", "-g", "daemon off;"]
```

**Daemon Mode:**
- Nginx runs in background
- Returns control to shell immediately
- Traditional for system services

**Daemon Off:**
- Nginx runs in foreground
- Keeps process as PID 1
- Container stays alive as long as nginx is running
- Required for Docker containers

**Without `daemon off;`:**
```
1. Container starts
2. Nginx forks to background
3. Parent process exits
4. PID 1 is gone
5. Container stops immediately
```

## Part 7: Environment Variables & Secrets

### Q19: How are environment variables managed?

**Answer:**
**In docker-compose.yml:**
```yaml
services:
  mariadb:
    env_file:
      - .env
```

**The .env file contains:**
```bash
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
MYSQL_PASSWORD=secretpassword
MYSQL_HOST=mariadb
DOMAIN_NAME=yojablao.42.fr
WP_TITLE="My Blog"
# ... etc
```

**Access in Scripts:**
```bash
mariadb -e "CREATE DATABASE $MYSQL_DATABASE;"
```

**Benefits:**
- Separate configuration from code
- Easy to change without rebuilding images
- Can use different .env files for dev/prod
- Not committed to git (add to .gitignore)

### Q20: What's in the secrets/ directory?

**Answer:**
Looking at your project:
```
secrets/
├── credentials.txt      [Empty]
├── db_password.txt      [Empty]
├── db_root_password.txt [Empty]
└── mouhcine.txt         [Contains: 1337]