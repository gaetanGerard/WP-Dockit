#!/bin/bash

# Stoppe les conteneurs WordPress
echo "🔍 Recherche des conteneurs WordPress à arrêter..."
wordpress_containers=$(docker ps -q --filter "name=wordpress-")

if [ -n "$wordpress_containers" ]; then
  echo "🛑 Arrêt des conteneurs WordPress..."
  docker stop $wordpress_containers
else
  echo "✅ Aucun conteneur WordPress en cours d'exécution."
fi

# Stoppe les conteneurs de base (db, phpmyadmin, mailhog)
echo "🛑 Arrêt des services de base..."
docker compose -f docker-compose.base.yml down

# Supprime le réseau partagé
if docker network ls | grep -q "shared_net"; then
  echo "🧹 Suppression du réseau 'shared_net'..."
  docker network rm shared_net
else
  echo "✅ Le réseau 'shared_net' n'existe pas ou est déjà supprimé."
fi
