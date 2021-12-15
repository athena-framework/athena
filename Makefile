-include Makefile.local # for optional local config

OUTPUT_DIR ?= ./site ## Build directory (default: ./site)
SHARDS_OVERRIDE ?= ./shard.yml

MKDOCS ?= .venv/bin/mkdocs
PIP ?= .venv/bin/pip
SHARDS ?= shards

DOCS_FILES := $(shell find docs -type f)

.PHONY: build
build: ## Build website into build directory
build: $(OUTPUT_DIR)

$(OUTPUT_DIR): $(DOCS_FILES) $(MKDOCS)
	$(MKDOCS) build -d $(OUTPUT_DIR) ## --strict

.PHONY: serve
serve: ## Run live-preview server
serve: $(MKDOCS)
	$(MKDOCS) serve

deps: $(MKDOCS)

$(MKDOCS): $(PIP) requirements.txt
	$(SHARDS) install -q
	$(PIP) install -q -r requirements.txt

$(PIP):
	python3 -m venv .venv

.PHONY: clean
clean: ## Remove build directory
	rm -rf $(OUTPUT_DIR)

.PHONY: clean_deps
clean_deps: ## Remove .venv directory
	rm -rf .venv
	rm -rf ./lib
