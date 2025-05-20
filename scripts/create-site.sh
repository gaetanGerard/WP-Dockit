#!/bin/bash

# Chemin du fichier contenant les ports réservés
RESERVED_PORTS_FILE="./scripts/reserved_ports.env"

# Charger la liste des ports réservés depuis le fichier
if [ -f "$RESERVED_PORTS_FILE" ]; then
  source "$RESERVED_PORTS_FILE"
  RESERVED_PORTS=($RESERVED_PORTS) # transforme en tableau
else
  echo "File $RESERVED_PORTS_FILE not found. Creating an empty file."
  echo 'RESERVED_PORTS=""' > "$RESERVED_PORTS_FILE"
  RESERVED_PORTS=()
fi

# Fonction pour vérifier si un port est utilisé ou réservé
is_port_in_use_or_reserved() {
  local port=$1
  # Vérifier si le port est utilisé par un processus en écoute
  if lsof -iTCP:$port -sTCP:LISTEN -t >/dev/null 2>&1; then
    return 0
  fi
  # Vérifier si le port est dans la liste des ports réservés
  for reserved in "${RESERVED_PORTS[@]}"; do
    if [[ "$reserved" == "$port" ]]; then
      return 0
    fi
  done
  return 1
}

# Trouve le premier port disponible à partir de 8000
find_first_free_port() {
  local port=8000
  while is_port_in_use_or_reserved $port; do
    ((port++))
  done
  echo $port
}

# Met à jour le fichier reserved_ports.env avec un nouveau port ajouté
update_reserved_ports() {
  local new_port=$1
  # Ajouter le port seulement s'il n'est pas déjà dans la liste
  if [[ ! " ${RESERVED_PORTS[*]} " =~ " $new_port " ]]; then
    RESERVED_PORTS+=($new_port)
  fi
  # Réécrire le fichier avec la liste mise à jour
  echo "RESERVED_PORTS=\"${RESERVED_PORTS[*]}\"" > "$RESERVED_PORTS_FILE"
}

echo "🔧 Creating a new WordPress project"

read -p "Folder name (e.g., my-site): " SITE_DIR
read -p "Site name (e.g., my_site): " SITE_NAME
read -p "Database name: " DB_NAME
read -p "DB user name: " DB_USER
read -p "DB password: " DB_PASSWORD

# Demande du port avec logique de fallback automatique
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

# Ajouter le port choisi à la liste des ports réservés
update_reserved_ports "$WP_PORT"

# Création des dossiers et fichiers
mkdir -p "$SITE_DIR/wordpress"

cat > "$SITE_DIR/.env" <<EOF
SITE_NAME=$SITE_NAME
DB_NAME=$DB_NAME
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
WP_PORT=$WP_PORT
EOF

cat > "$SITE_DIR/docker-compose.yml" <<EOF
services:
  wordpress:
    image: wordpress:6.5-php8.2-apache
    container_name: wordpress-${SITE_NAME}
    depends_on:
      - init-db
    ports:
      - "${WP_PORT}:80"
    environment:
      WORDPRESS_DB_HOST: db:3306
      WORDPRESS_DB_NAME: ${DB_NAME}
      WORDPRESS_DB_USER: ${DB_USER}
      WORDPRESS_DB_PASSWORD: ${DB_PASSWORD}
    volumes:
      - ./wordpress:/var/www/html
    networks:
      - shared_net

  init-db:
    image: mysql:8.0
    command: >
      sh -c "
        until mysqladmin ping -h db --silent; do sleep 2; done;
        mysql -h db -u root -proot -e \"
          CREATE DATABASE IF NOT EXISTS ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
          CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
          GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'%';
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
