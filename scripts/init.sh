#!/bin/bash

# Script d'initialisation du projet

# Crée le réseau Docker s’il n'existe pas
if ! docker network ls | grep -q "shared_net"; then
  echo "Création du réseau Docker 'shared_net'..."
  docker network create shared_net
else
  echo "Le réseau 'shared_net' existe déjà."
fi

# Démarre les services de base
echo "Lancement des services de base..."
docker compose -f docker-compose.base.yml up -d
