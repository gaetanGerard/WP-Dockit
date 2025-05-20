SHELL := /bin/bash

.PHONY: init new-site cleanup remove-site regenerate-ports

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
