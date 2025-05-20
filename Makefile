SHELL := /bin/bash

.PHONY: help init new-site cleanup remove-site regenerate-ports start-site stop-site

# Si aucune commande n'est fournie => afficher l'aide
.DEFAULT_GOAL := help

help:
	@echo ""
	@echo "📦 Available commands:"
	@echo ""
	@echo "  make init                🔧 Initialize the environment (MySQL, phpmyadmin, mailhog.)"
	@echo "  make new-site            ➕ Create a new WordPress site with an available port"
	@echo "  make start-site          🚀 Start an existing site (with port check)"
	@echo "  make stop-site           🛑 Stop an existing WordPress site and clean up related containe"
	@echo "  make remove-site         ❌ Remove an existing site"
	@echo "  make cleanup             🧹 Stop services container, running Wordpress container, and remove network"
	@echo "  make regenerate-ports    ♻️  Regenerate the list of reserved ports based on active projects"
	@echo "  make help                📘 Show this help message"
	@echo ""

init:
	@bash scripts/init.sh

new-site:
	@bash scripts/create-site.sh

cleanup:
	@bash scripts/cleanup.sh

remove-site:
	@bash scripts/remove-site.sh

regenerate-ports:
	@bash scripts/regenerate_reserved_ports.sh

start-site:
	@bash ./scripts/start-site.sh

stop-site:
	bash scripts/stop-wp-site.sh