# Utilitaires
SHELL := /bin/bash

.PHONY: init new-site cleanup

init:
	@bash scripts/init.sh

new-site:
	@bash scripts/create-site.sh

cleanup:
	@bash scripts/cleanup.sh
