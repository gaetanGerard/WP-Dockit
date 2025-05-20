#!/bin/bash

# Script for removing a site

read -p "Name of the site folder to remove: " SITE_DIR

# Check if folder exists
if [ ! -d "$SITE_DIR" ]; then
  echo "❌ The folder '$SITE_DIR' does not exist."
  exit 1
fi

# Read if DB and port are present in .env
ENV_FILE="$SITE_DIR/.env"
if [ ! -f "$ENV_FILE" ]; then
  echo "❌ .env file not found in $SITE_DIR."
  exit 1
fi

source "$ENV_FILE"

if [[ -z "$WP_PORT" || -z "$DB_NAME" ]]; then
  echo "❌ WP_PORT or DB_NAME variables missing in $ENV_FILE."
  exit 1
fi

# remove the port from reserved_ports.env
RESERVED_FILE="./scripts/reserved_ports.env"

if [ -f "$RESERVED_FILE" ]; then
  source "$RESERVED_FILE"
  RESERVED_ARRAY=($RESERVED_PORTS)
  NEW_RESERVED=()

  for port in "${RESERVED_ARRAY[@]}"; do
    if [[ "$port" != "$WP_PORT" ]]; then
      NEW_RESERVED+=("$port")
    fi
  done

  echo "RESERVED_PORTS=\"${NEW_RESERVED[*]}\"" > "$RESERVED_FILE"
  echo "🧹 Port $WP_PORT removed from reserved_ports.env"
fi

# remove site container
docker compose -f "$SITE_DIR/docker-compose.yml" down --volumes
rm -rf "$SITE_DIR"
echo "🗑️  Folder '$SITE_DIR' deleted."

# Ask user if they want to delete the database
read -p "Do you want to delete the database '$DB_NAME'? (y/N): " CONFIRM_DB
CONFIRM_DB=${CONFIRM_DB,,} # Convert to lowercase

if [[ "$CONFIRM_DB" == "y" || "$CONFIRM_DB" == "yes" ]]; then
  # Check if the database is running
  DB_RUNNING=$(docker compose -f docker-compose.base.yml ps -q db | xargs docker inspect -f '{{.State.Running}}' 2>/dev/null)
  DB_STARTED_BY_SCRIPT=false

  if [ "$DB_RUNNING" != "true" ]; then
    echo "⚙️  MySQL service is stopped. Starting temporarily..."
    docker compose -f docker-compose.base.yml up -d db
    DB_STARTED_BY_SCRIPT=true
    sleep 5
  fi

  docker compose -f docker-compose.base.yml exec -T db mysql -uroot -proot -e "DROP DATABASE IF EXISTS \`$DB_NAME\`;"
  echo "🧨 Database '$DB_NAME' deleted."

  if [ "$DB_STARTED_BY_SCRIPT" = true ]; then
    echo "🛑 Stopping temporarily started MySQL service..."
    docker compose -f docker-compose.base.yml stop db
  fi
else
  echo "📦 The database '$DB_NAME' has been kept."
fi

echo "✅ Site removal completed."
