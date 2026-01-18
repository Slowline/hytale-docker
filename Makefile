.DEFAULT_GOAL := help
SHELL := /usr/bin/env bash
MAKEFLAGS += --no-builtin-rules --warn-undefined-variables

VERBOSE ?= 0
NO_COLOR ?= 0

COMPOSE := docker compose -f docker-compose.yml
SERVICE ?= hytale-server
CMD ?= list
WAIT_TIMEOUT ?= 300

# ---- Targets ---------------------------------------------------------------
.PHONY: build up down restart status logs in update update-hytale-downloader auth attach help

##@ Container
build: ## Build server docker image
	@$(COMPOSE) build --pull $(SERVICE)

up: ## Start the server
	@$(COMPOSE) up --detach --wait --wait-timeout=$(WAIT_TIMEOUT)

down: ## Stop the server and remove resources
	@$(COMPOSE) down --remove-orphans

restart: ## Restart the server
	@$(COMPOSE) down && $(COMPOSE) up --detach --wait --wait-timeout=$(WAIT_TIMEOUT)

status: ## Show container status
	@$(COMPOSE) ps -a --format "table {{.Name}}\t{{.Service}}\t{{.State}}\t{{.Status}}\t{{.Ports}}"

logs: ## Tail server logs
	@$(COMPOSE) logs --tail=200 --follow $(SERVICE)

in: ## Container shell
	@$(COMPOSE) exec $(SERVICE) /bin/bash

##@ Hytale Server
attach: ## Attach to the server console
	@docker attach hytale

##@ Hytale Server and Downloader CLI updates
update: ## Update Hytale Server
	@$(COMPOSE) exec $(SERVICE) bash -lc '\
		set -e; \
		JAR_FILE="/hytale/Server/HytaleServer.jar"; \
		DOWNLOADER_BIN="$${DOWNLOADER_BIN:-hytale-downloader}"; \
		AVAILABLE_VERSION_RAW="$$( $$DOWNLOADER_BIN -print-version 2>&1 || true )"; \
		AVAILABLE_VERSION="$$( echo "$$AVAILABLE_VERSION_RAW" | tr -d "\r" | tail -n 1 | sed "s/^[[:space:]]*//;s/[[:space:]]*$$//" )"; \
		echo "Available HytaleServer.jar version: $$AVAILABLE_VERSION"; \
		INSTALLED_VERSION=""; \
		if [ -f "$$JAR_FILE" ]; then \
			INSTALLED_VERSION_RAW="$$( java -jar "$$JAR_FILE" --version 2>&1 || true )"; \
			INSTALLED_VERSION="$$( echo "$$INSTALLED_VERSION_RAW" | tr -d "\r" | sed -n "s/.*v\\([^ ]*\\).*/\\1/p" | head -n 1 | sed "s/^[[:space:]]*//;s/[[:space:]]*$$//" )"; \
			if [ -z "$$INSTALLED_VERSION" ]; then \
				echo "WARNING: Could not extract version from installed jar. Output was:"; \
				echo "$$INSTALLED_VERSION_RAW"; \
				echo "Treating as outdated and will download..."; \
			else \
				echo "Installed HytaleServer.jar version: $$INSTALLED_VERSION"; \
			fi; \
		else \
			echo "HytaleServer.jar not found. Will download..."; \
		fi; \
		NEED_DOWNLOAD="false"; \
		if [ ! -f "$$JAR_FILE" ]; then \
			NEED_DOWNLOAD="true"; \
			echo "Server jar missing. Downloading..."; \
		elif [ -z "$$INSTALLED_VERSION" ] || [ "$$INSTALLED_VERSION" != "$$AVAILABLE_VERSION" ]; then \
			NEED_DOWNLOAD="true"; \
			if [ -n "$$INSTALLED_VERSION" ]; then \
				echo "Version mismatch detected ($$INSTALLED_VERSION -> $$AVAILABLE_VERSION). Downloading update..."; \
			fi; \
		else \
			echo "HytaleServer.jar is up to date"; \
		fi; \
		if [ "$$NEED_DOWNLOAD" = "true" ]; then \
			DOWNLOAD_ZIP="/hytale/game.zip"; \
			set +e; \
			$$DOWNLOADER_BIN -download-path "$$DOWNLOAD_ZIP"; \
			EXIT_CODE="$$?"; \
			set -e; \
			if [ "$$EXIT_CODE" -ne 0 ]; then \
				echo "Downloader error: $$EXIT_CODE"; \
				if grep -q "403 Forbidden" <<< "$$( $$DOWNLOADER_BIN -print-version 2>&1 || true )"; then \
					if [ "$${SKIP_DELETE_ON_FORBIDDEN:-false}" = "true" ]; then \
						echo "403 Forbidden detected! SKIP_DELETE_ON_FORBIDDEN=true, keeping downloader credentials."; \
					else \
						echo "403 Forbidden detected! Clearing downloader credentials..."; \
						rm -f ~/.hytale-downloader-credentials.json; \
					fi; \
				fi; \
				exit "$$EXIT_CODE"; \
			fi; \
			if [ ! -f "$$DOWNLOAD_ZIP" ]; then \
				echo "ERROR: Download expected at $$DOWNLOAD_ZIP but file not found."; \
				exit 1; \
			fi; \
			echo "Unpacking $$DOWNLOAD_ZIP into /hytale ..."; \
			rm -f "$$JAR_FILE"; \
			unzip -o "$$DOWNLOAD_ZIP" -d /hytale; \
			rm -f "$$DOWNLOAD_ZIP"; \
			echo "Update completed."; \
		fi'

update-hytale-downloader: ## Update Hytale Downloader CLI
	@$(COMPOSE) exec $(SERVICE) bash -lc 'hytale-downloader -check-update'

##@ Information
help: ## Displays this help menu
	@echo ""
	@printf "   ██╗  ██╗██╗   ██╗████████╗ █████╗ ██╗     ███████╗   \n"
	@printf "   ██║  ██║╚██╗ ██╔╝╚══██╔══╝██╔══██╗██║     ██╔════╝   \n"
	@printf "   ███████║ ╚████╔╝    ██║   ███████║██║     █████╗     \n"
	@printf "   ██╔══██║  ╚██╔╝     ██║   ██╔══██║██║     ██╔══╝     \n"
	@printf "   ██║  ██║   ██║      ██║   ██║  ██║███████╗███████╗   \n"
	@printf "   ╚═╝  ╚═╝   ╚═╝      ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝   \n"
	@printf "            https://github.com/Slowline/hytale-docker   \n"
	@awk 'BEGIN {FS = ":.*##"; pad=24; \
	    b="\033[1m"; r="\033[0m"; command="\033[0;97m"; comment="\033[38;5;247m"; dim="\033[2m"; white="\033[97m"; } \
	  /^##@/ {printf "\n" white " 🅷  %s" r "\n" dim " ──────────────────────────────────────────────────────────────────" r "\n", substr($$0,5)} \
	  /^[a-zA-Z0-9_.%-]+:.*##/ {printf "  " command "%-" pad "s" r comment " %s" r "\n", $$1, $$2}' \
	  $(MAKEFILE_LIST)
	@echo ""
