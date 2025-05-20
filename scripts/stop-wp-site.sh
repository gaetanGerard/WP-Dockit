#!/bin/bash

# Prompt for site(s) to stop
read -p "Name(s) of the site folder(s) to stop (e.g., site-1,site-2 or 'all'): " INPUT

# Get list of all WordPress site folders (docker-compose.yml must exist inside)
ALL_SITES=$(find . -maxdepth 2 -name "docker-compose.yml" -exec dirname {} \; | sed 's|^\./||')

# Handle 'all' keyword
if [ "$INPUT" == "all" ]; then
  SITES="$ALL_SITES"
else
  # Split by comma into array
  IFS=',' read -ra SITES_ARRAY <<< "$INPUT"
  for SITE in "${SITES_ARRAY[@]}"; do
    if [[ ! " $ALL_SITES " =~ (^|[[:space:]])"$SITE"($|[[:space:]]) ]]; then
      echo "❌ Site '$SITE' not found or missing docker-compose.yml."
      exit 1
    fi
  done
  SITES="${SITES_ARRAY[@]}"
fi

for SITE_NAME in $SITES; do
  SITE_DIR="./$SITE_NAME"
  echo "🛑 Stopping WordPress site '$SITE_NAME'..."
  docker compose -f "$SITE_DIR/docker-compose.yml" down

  # Remove any stopped containers with matching name
  CONTAINERS=$(docker ps -a --filter "name=$SITE_NAME" --format "{{.ID}}")
  if [ -n "$CONTAINERS" ]; then
    echo "🧹 Removing stopped containers related to '$SITE_NAME'..."
    docker rm -f $CONTAINERS
  fi
done

# Global cleanup
echo "🧼 Cleaning up unused Docker resources..."
docker system prune -f

echo "✅ Done. Site(s) stopped and cleaned."
