#!/bin/bash

# Script d'initialisation du projet

RESERVED_PORTS_FILE="./scripts/reserved_ports.env"
TEMPLATE_FILE="./scripts/template.reserved_ports.env"

# Vérifie si reserved_ports.env existe, sinon le crée à partir du template ou avec une valeur par défaut
if [ ! -f "$RESERVED_PORTS_FILE" ]; then
  echo "Fichier reserved_ports.env introuvable."
  if [ -f "$TEMPLATE_FILE" ]; then
    echo "📄 Copie de template.reserved_ports.env vers reserved_ports.env"
    cp "$TEMPLATE_FILE" "$RESERVED_PORTS_FILE"
  else
    echo "⚠️ Aucun template trouvé. Création d’un fichier reserved_ports.env avec 8025 comme port réservé par défaut."
    echo 'RESERVED_PORTS="8025"' > "$RESERVED_PORTS_FILE"
  fi
fi

# Crée le réseau Docker s’il n'existe pas
if ! docker network ls | grep -q "shared_net"; then
  echo "🔌 Création du réseau Docker 'shared_net'..."
  docker network create shared_net
else
  echo "🔁 Le réseau 'shared_net' existe déjà."
fi

# Démarre les services de base
echo "🚀 Lancement des services de base..."
docker compose -f docker-compose.base.yml up -d
