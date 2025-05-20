#!/bin/bash

# Script to regenerate reserved_ports.env based on existing site .env files

RESERVED_FILE="./scripts/reserved_ports.env"
SITES_DIR="."

PORTS=()

for env_file in "$SITES_DIR"/*/.env; do
  if [ -f "$env_file" ]; then
    source "$env_file"
    if [ ! -z "$WP_PORT" ]; then
      PORTS+=("$WP_PORT")
    fi
  fi
done

# remove duplicates
UNIQUE_PORTS=($(echo "${PORTS[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))

# Regenerate the reserved_ports.env file
echo "RESERVED_PORTS=\"${UNIQUE_PORTS[*]}\"" > "$RESERVED_FILE"

echo "✅ reserved_ports.env regenerated with ports: ${UNIQUE_PORTS[*]}"
