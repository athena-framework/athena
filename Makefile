-include Makefile.local # for optional local config

OUTPUT_DIR ?= ./site ## Build directory (default: ./site)

MKDOCS ?= ./.venv/bin/mkdocs
PIP ?= ./.venv/bin/pip3
PIP_COMPILE ?= ./.venv/bin/pip-compile

.PHONY: build
build: ## Build website into build directory
build: $(OUTPUT_DIR)

$(OUTPUT_DIR): $(MKDOCS)
	$(MKDOCS) build -d $(OUTPUT_DIR)

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

.PHONY: upgrade
upgrade: ## Upgrade mkdocs deps
	$(PIP_COMPILE) -U requirements.in

.PHONY: clean
clean: ## Remove build directories
	rm -rf $(OUTPUT_DIR)
	find src/components -type d -name "site" -exec rm -rf {} +

.PHONY: clean_deps
clean_deps: ## Remove .venv directory
	rm -rf .venv
