# Config

OUTPUT_DIR := './site'

# Binaries

MKDOCS := './.venv/bin/mkdocs'
PIP := './.venv/bin/pip3'
PIP_COMPILE := './.venv/bin/pip-compile'

# Ensure when MkDocs is generating the docs for each component it's able to find their shard dependencies
# via the monorepo's `lib/` dir versus `src/components/<name>/lib`.

export CRYSTAL_PATH := invocation_directory() + '/lib:' + `crystal env CRYSTAL_PATH`

_default:
    @just --list --unsorted

# Runs (`all|unit|compiled`) specs for the provided component
[group('dev')]
test component type='all':
    ./scripts/test.sh {{component}} {{type}}

# Runs and watches for changes to the main entrypoint file of the provided component
[group('dev')]
watch component:
    watchexec --restart --watch=src/ --emit-events-to=none --clear -- crystal run src/components/{{component}}/src/athena-{{component}}.cr

# Runs (`all|unit|compiled`) specs, and watches for changes to the provided component
[group('dev')]
watch-spec component type='all':
    watchexec --restart --watch=src/ --emit-events-to=none --clear -- ./scripts/test.sh {{component}} {{type}}

# Build the docs
[group('docs')]
build-docs: _mkdocs
    {{ MKDOCS }} build -d {{ OUTPUT_DIR }}

# Serve live-preview of the docs
[group('docs')]
serve-docs: _mkdocs
    {{ CRYSTAL_PATH }} {{ MKDOCS }} serve --open

# Clean MKDocs build artifacts
[group('docs')]
clean-docs:
    rm -rf {{ OUTPUT_DIR }}
    find src/components -type d -name "site" -exec rm -rf {} +

# Upgrade python deps
[group('administrative')]
upgrade: _pip
    {{ PIP_COMPILE }} -U requirements.in


# Clean build artifacts (.venv)
[group('administrative')]
clean_deps:
    rm -rf .venv

_pip:
    python3 -m venv .venv
    {{ PIP }} install -q pip-tools

_mkdocs: _pip
    {{ PIP }} install -q -r requirements.txt
