SHELL := /bin/bash

.PHONY: init new-site cleanup remove-site

init:
	@bash scripts/init.sh

new-site:
	@bash scripts/create-site.sh

cleanup:
	@bash scripts/cleanup.sh

remove-site:
	@bash scripts/remove-site.sh
