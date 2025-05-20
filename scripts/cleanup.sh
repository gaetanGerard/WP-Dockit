#!/bin/bash

# Stop Wordpress containers
echo "🔍 Looking for running WordPress containers to stop...."
wordpress_containers=$(docker ps -q --filter "name=wordpress-")

if [ -n "$wordpress_containers" ]; then
  echo "🛑 Stopping WordPress containers..."
  docker stop $wordpress_containers
else
  echo "✅ No running WordPress containers found."
fi

# Stop services containers (db, phpmyadmin, mailhog)
echo "🛑 Stopping base services..."
docker compose -f docker-compose.base.yml down

# Remove network
if docker network ls | grep -q "shared_net"; then
  echo "🧹 Removing 'shared_net' Docker network..."
  docker network rm shared_net
else
  echo "✅ 'shared_net' network does not exist or has already been removed."
fi
