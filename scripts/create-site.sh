#!/bin/bash

# Path to the reserved ports file
RESERVED_PORTS_FILE="./scripts/reserved_ports.env"

# Load the reserved ports from the file
if [ -f "$RESERVED_PORTS_FILE" ]; then
  source "$RESERVED_PORTS_FILE"
  RESERVED_PORTS=($RESERVED_PORTS) # Convert string to array
else
  echo "File $RESERVED_PORTS_FILE not found. Creating an empty file."
  echo 'RESERVED_PORTS=""' > "$RESERVED_PORTS_FILE"
  RESERVED_PORTS=()
fi

# Check if a port is in use or reserved
is_port_in_use_or_reserved() {
  local port=$1
  if lsof -iTCP:$port -sTCP:LISTEN -t >/dev/null 2>&1; then
    return 0
  fi
  for reserved in "${RESERVED_PORTS[@]}"; do
    if [[ "$reserved" == "$port" ]]; then
      return 0
    fi
  done
  return 1
}

# Find the first free port starting from 8000
find_first_free_port() {
  local port=8000
  while is_port_in_use_or_reserved $port; do
    ((port++))
  done
  echo $port
}

# Update the reserved ports file
update_reserved_ports() {
  local new_port=$1
  if [[ ! " ${RESERVED_PORTS[*]} " =~ " $new_port " ]]; then
    RESERVED_PORTS+=($new_port)
  fi
  echo "RESERVED_PORTS=\"${RESERVED_PORTS[*]}\"" > "$RESERVED_PORTS_FILE"
}

echo "🔧 Creating a new WordPress project"

read -p "Folder name (e.g., my-site): " SITE_DIR
read -p "Site name (e.g., my_site): " SITE_NAME
read -p "Database name: " DB_NAME
read -p "DB user name: " DB_USER
read -p "DB password: " DB_PASSWORD

# add automatic fallback for the port
while true; do
  read -p "Desired WordPress port (leave blank for auto): " WP_PORT

  if [[ -z "$WP_PORT" ]]; then
    WP_PORT=$(find_first_free_port)
    echo "🧠 Auto-selected port: $WP_PORT"
    break
  elif ! [[ "$WP_PORT" =~ ^[0-9]+$ ]]; then
    echo "❌ The port must be a number"
    continue
  elif is_port_in_use_or_reserved "$WP_PORT"; then
    SUGGESTED_PORT=$(find_first_free_port)
    echo "❌ Port $WP_PORT is already in use or reserved. Available example: $SUGGESTED_PORT"
  else
    echo "✅ Port $WP_PORT is free."
    break
  fi
done

# Add the port to the reserved ports file
update_reserved_ports "$WP_PORT"

# Retrieve the user and group IDs
USER_ID=$(id -u)
GROUP_ID=$(id -g)

# Create the site directory
mkdir -p "$SITE_DIR/wordpress"
chown -R "$USER_ID:$GROUP_ID" "$SITE_DIR/wordpress"

# Generate the .env file
cat > "$SITE_DIR/.env" <<EOF
SITE_NAME=$SITE_NAME
DB_NAME=$DB_NAME
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
WP_PORT=$WP_PORT
USER_ID=$USER_ID
GROUP_ID=$GROUP_ID
EOF

# Generate the docker-compose.yml file
cat > "$SITE_DIR/docker-compose.yml" <<EOF
services:
  wordpress:
    image: wordpress:6.5-php8.2-apache
    container_name: wordpress-${SITE_NAME}
    depends_on:
      - init-db
    ports:
      - "\${WP_PORT}:80"
    environment:
      WORDPRESS_DB_HOST: db:3306
      WORDPRESS_DB_NAME: \${DB_NAME}
      WORDPRESS_DB_USER: \${DB_USER}
      WORDPRESS_DB_PASSWORD: \${DB_PASSWORD}
    volumes:
      - ./wordpress:/var/www/html
    user: "\${USER_ID}:\${GROUP_ID}"
    networks:
      - shared_net

  init-db:
    image: mysql:8.0
    command: >
      sh -c "
        until mysqladmin ping -h db --silent; do sleep 2; done;
        mysql -h db -u root -proot -e \"
          CREATE DATABASE IF NOT EXISTS \${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
          CREATE USER IF NOT EXISTS '\${DB_USER}'@'%' IDENTIFIED BY '\${DB_PASSWORD}';
          GRANT ALL PRIVILEGES ON \${DB_NAME}.* TO '\${DB_USER}'@'%';
          FLUSH PRIVILEGES;
        \"
      "
    networks:
      - shared_net

networks:
  shared_net:
    external: true
EOF

echo "✅ Project '$SITE_DIR' has been successfully initialized (port $WP_PORT)."
