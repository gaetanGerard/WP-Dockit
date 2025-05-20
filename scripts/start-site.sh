#!/bin/bash

read -p "Name(s) of the site folder(s) to start (e.g., site-1 or site-1,site-2): " INPUT

# Split input into array
IFS=',' read -ra SITES <<< "$INPUT"

RESERVED_FILE="./scripts/reserved_ports.env"
TEMPLATE_FILE="./scripts/template.reserved_ports.env"
REGENERATE_SCRIPT="./scripts/regenerate_reserved_ports.sh"
DOCKER_NETWORK="shared_net"
BASE_COMPOSE_FILE="docker-compose.base.yml"

# Load reserved and template ports
declare -a RESERVED_PORTS
TEMPLATE_PORTS=""

if [ -f "$RESERVED_FILE" ]; then
  source "$RESERVED_FILE"
  RESERVED_PORTS=($RESERVED_PORTS)
fi

if [ -f "$TEMPLATE_FILE" ]; then
  TEMPLATE_PORTS=$(grep -E '^[[:space:]]*[A-Z_]+_PORT=[0-9]+' "$TEMPLATE_FILE" | grep -o '[0-9]\+')
fi

network_exists() {
  docker network ls --format '{{.Name}}' | grep -qw "$DOCKER_NETWORK"
}

base_services_running() {
  containers=$(docker compose -f "$BASE_COMPOSE_FILE" ps -q)
  if [ -z "$containers" ]; then return 1; fi
  for container in $containers; do
    running=$(docker inspect -f '{{.State.Running}}' "$container" 2>/dev/null)
    [[ "$running" == "true" ]] && return 0
  done
  return 1
}

is_port_in_use_or_reserved() {
  local port=$1
  if lsof -iTCP:$port -sTCP:LISTEN -t >/dev/null 2>&1; then return 0; fi
  for p in "${RESERVED_PORTS[@]}"; do [[ "$p" == "$port" ]] && return 0; done
  echo "$TEMPLATE_PORTS" | grep -q "^$port$" && return 0
  return 1
}

find_project_using_port() {
  local search_port=$1
  for dir in */; do
    [[ "$dir" == "$SITE_DIR/" ]] && continue
    [[ -f "${dir}.env" ]] || continue
    source "${dir}.env"
    [[ "$WP_PORT" == "$search_port" ]] && echo "${dir%/}" && return
  done
}

# Start base services if needed
if ! network_exists || ! base_services_running; then
  echo "🔧 Docker network '$DOCKER_NETWORK' or base services not running. Executing init.sh ..."
  ./scripts/init.sh
else
  echo "✅ Docker network and base services are running."
fi

# Ensure regenerate_reserved_ports.sh is executable
if [ ! -x "$REGENERATE_SCRIPT" ]; then
  echo "🔧 Making $REGENERATE_SCRIPT executable..."
  chmod +x "$REGENERATE_SCRIPT"
fi

# Loop through each site
for SITE_DIR in "${SITES[@]}"; do
  if [ ! -d "$SITE_DIR" ]; then
    echo "❌ Folder '$SITE_DIR' does not exist."
    continue
  fi

  ENV_FILE="$SITE_DIR/.env"
  if [ ! -f "$ENV_FILE" ]; then
    echo "❌ .env file not found in '$SITE_DIR'."
    continue
  fi

  source "$ENV_FILE"
  WP_PORT=${WP_PORT:-}

  if [[ -z "$WP_PORT" ]]; then
    echo "❌ WP_PORT not defined in $ENV_FILE"
    continue
  fi

  PORT_IN_USE=false

  # Check for conflicts
  if echo "$TEMPLATE_PORTS" | grep -q "^$WP_PORT$"; then
    echo "❌ Port $WP_PORT is reserved for system services."
    PORT_IN_USE=true
  elif [[ " ${RESERVED_PORTS[*]} " =~ " $WP_PORT " ]]; then
    project_name=$(find_project_using_port "$WP_PORT")
    if [[ -n "$project_name" ]]; then
      echo "❌ Port $WP_PORT is already used by project '$project_name'."
      PORT_IN_USE=true
    fi
  elif lsof -iTCP:$WP_PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "❌ Port $WP_PORT is currently in use by another process."
    PORT_IN_USE=true
  fi

  # Suggest a new port if needed
  if $PORT_IN_USE; then
    NEW_PORT=8000
    while is_port_in_use_or_reserved "$NEW_PORT"; do ((NEW_PORT++)); done

    echo "💡 Suggested available port for '$SITE_DIR': $NEW_PORT"
    read -p "Enter new port (press Enter to use $NEW_PORT): " CUSTOM_PORT
    SELECTED_PORT=${CUSTOM_PORT:-$NEW_PORT}

    while is_port_in_use_or_reserved "$SELECTED_PORT"; do
      echo "❌ Port $SELECTED_PORT is still not available."
      read -p "Enter another port: " SELECTED_PORT
    done

    if [[ "$OSTYPE" == "darwin"* ]]; then
      sed -i '' -e "s/^WP_PORT=.*/WP_PORT=$SELECTED_PORT/" "$ENV_FILE"
    else
      sed -i "s/^WP_PORT=.*/WP_PORT=$SELECTED_PORT/" "$ENV_FILE"
    fi
    WP_PORT=$SELECTED_PORT

    echo "✅ Port updated to $WP_PORT"
  fi

  # Regenerate reserved ports before starting
  "$REGENERATE_SCRIPT"

  # Restart site containers
  docker compose -f "$SITE_DIR/docker-compose.yml" down
  docker compose -f "$SITE_DIR/docker-compose.yml" rm -f
  docker compose -f "$SITE_DIR/docker-compose.yml" up -d

  echo "🚀 Site '$SITE_DIR' started on port $WP_PORT."
  echo "🌐 Access: http://localhost:$WP_PORT"
done
