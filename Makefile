# Determine this makefile's path.
# Be sure to place this BEFORE `include` directives, if any.
# THIS_FILE := $(lastword $(MAKEFILE_LIST))
THIS_FILE := $(abspath $(lastword $(MAKEFILE_LIST)))
CURRENT_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

include vars.mk

.PHONY: build
build: ## build Docker image locally
	docker build -t $(APACHE_JENA_FUSEKI_IMAGE) .
	docker tag $(APACHE_JENA_FUSEKI_IMAGE) $(APACHE_JENA_FUSEKI_REPO):latest

.PHONY: publish
publish: build ## publish Docker image to Docker-Hub
	docker push $(APACHE_JENA_FUSEKI_REPO)

.PHONY: help
help: ## this help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST) | sort

.DEFAULT_GOAL := help
