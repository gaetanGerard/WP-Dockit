#!/bin/bash

RESERVED_FILE="./scripts/reserved_ports.env"
TEMPLATE_FILE="./scripts/template.reserved_ports.env"
SITES_DIR="."

# Create template.reserved_ports.env if it does not exist
if [ ! -f "$TEMPLATE_FILE" ]; then
  echo "⚠️  No template.reserved_ports.env file found."
  echo "📄 Creating template.reserved_ports.env with default reserved ports (e.g. Mailhog, PhpMyAdmin)."
  {
    echo "# 🛑 You can declare ports to reserve here."
    echo "# ℹ️ Only lines with variable names ending in _PORT and values between 8000 and 8999 will be included in reserved_ports.env"
    echo "# Example:"
    echo 'MAILHOG_PORT=8025'
    echo 'PHPMYADMIN_PORT=8080'
  } > "$TEMPLATE_FILE"
fi

PORTS=()

# Extract ports from existing sites
for env_file in "$SITES_DIR"/*/.env; do
  if [ -f "$env_file" ]; then
    source "$env_file"
    if [[ ! -z "$WP_PORT" && "$WP_PORT" =~ ^[0-9]+$ ]]; then
      PORTS+=("$WP_PORT")
    fi
  fi
done

# Extract ports from template.reserved_ports.env
if [ -f "$TEMPLATE_FILE" ]; then
  while IFS= read -r line; do
    if [[ "$line" =~ ^#.*$ || -z "$line" ]]; then
      continue
    fi

    # Retrieve the port number from the line
    if [[ "$line" =~ ^[A-Z_]+_PORT=([0-9]+)$ ]]; then
      port="${BASH_REMATCH[1]}"
      if [[ "$port" -ge 8000 && "$port" -le 8999 ]]; then
        PORTS+=("$port")
      fi
    fi
  done < "$TEMPLATE_FILE"
fi

# Remove duplicates and sort the ports
UNIQUE_PORTS=($(printf "%s\n" "${PORTS[@]}" | sort -n | uniq))

# Write the unique ports to reserved_ports.env
echo "RESERVED_PORTS=\"${UNIQUE_PORTS[*]}\"" > "$RESERVED_FILE"

echo "🗂️  reserved_ports.env regenerated with ports: ${UNIQUE_PORTS[*]}"
