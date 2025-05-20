#!/bin/bash

# Script to initialize the Docker environment for the project

REGENERATE_SCRIPT="./scripts/regenerate_reserved_ports.sh"

# Execute regenerate_reserved_ports file to recreate  template.reserved_ports.env and reserved_ports.env if it does not exist
echo "🔄 Regenerate reserved_ports.env from existing projects and template..."
bash "$REGENERATE_SCRIPT"

# Add network if it does not exist
if ! docker network ls | grep -q "shared_net"; then
  echo "🔌 Create Docker Network 'shared_net'..."
  docker network create shared_net
else
  echo "🔁 Docker network 'shared_net' already exist."
fi

# Start the base services
echo "🚀 Start Base services..."
docker compose -f docker-compose.base.yml up -d
