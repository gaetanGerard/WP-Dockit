#!/bin/bash

# Script to initialize the Docker environment for the project

RESERVED_PORTS_FILE="./scripts/reserved_ports.env"
TEMPLATE_FILE="./scripts/template.reserved_ports.env"

# Check if reserved_ports.env file exists if not create it from template and if template not exists create it with default port
if [ ! -f "$RESERVED_PORTS_FILE" ]; then
  echo "File reserved_ports.env not found."
  if [ -f "$TEMPLATE_FILE" ]; then
    echo "📄 Copying template.reserved_ports.env to reserved_ports.env"
    cp "$TEMPLATE_FILE" "$RESERVED_PORTS_FILE"
  else
    echo "⚠️ No template found. Creating reserved_ports.env file with 8025 as default reserved port."
    echo 'RESERVED_PORTS="8025"' > "$RESERVED_PORTS_FILE"
  fi
fi

# Add network if it doesn't exist
if ! docker network ls | grep -q "shared_net"; then
  echo "🔌 Creating Docker network 'shared_net'..."
  docker network create shared_net
else
  echo "🔁 Docker network 'shared_net' already exists."
fi

# Start the base services
echo "🚀 Starting base services..."
docker compose -f docker-compose.base.yml up -d
