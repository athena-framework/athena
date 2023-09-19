-include Makefile.local # for optional local config

OUTPUT_DIR ?= ./site ## Build directory (default: ./site)

MKDOCS ?= ./.venv/bin/mkdocs
PIP ?= ./.venv/bin/pip3

.PHONY: build
build: ## Build website into build directory
build: $(OUTPUT_DIR)

$(OUTPUT_DIR): $(MKDOCS)
	$(MKDOCS) build -d $(OUTPUT_DIR) --strict

.PHONY: serve
serve: ## Run live-preview server
serve: $(MKDOCS)
	$(MKDOCS) serve

deps: $(MKDOCS)

$(MKDOCS): $(PIP) requirements.txt
	$(PIP) install -q -r requirements.txt

$(PIP):
	python3 -m venv .venv
	./.venv/bin/pip3 install -q pip-tools

.PHONY: clean
clean: ## Remove build directory
	rm -rf $(OUTPUT_DIR)

.PHONY: clean_deps
clean_deps: ## Remove .venv directory
	rm -rf .venv
