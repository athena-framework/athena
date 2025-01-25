# Configuration

OUTPUT_DIR := './site'

# Binaries
# Scoped to the justfile so do not need to be exported

MKDOCS := './.venv/bin/mkdocs'
PIP := './.venv/bin/pip3'
PIP_COMPILE := './.venv/bin/pip-compile'

# Needs to be exported so that the `spec` component can pick up on the customized $CRYSTAL env var.

export CRYSTAL := 'crystal'

# Ensure when MkDocs is generating the docs for each component it's able to find their shard dependencies
# via the monorepo's `lib/` dir versus `src/components/<name>/lib` which doesn't exist.

# export CRYSTAL_PATH := invocation_directory_native() + '/lib:' + shell( '$1 env CRYSTAL_PATH', CRYSTAL )

_default:
    @just --list --unsorted

# Installs dev dependencies
[group('dev')]
install:
    SHARDS_OVERRIDE=shard.dev.yml shards update

# Runs and watches for changes to the main entrypoint file of the provided `component`
[group('dev')]
watch component:
    watchexec --restart --watch=src/ --emit-events-to=none --clear -- {{ CRYSTAL }} run src/components/{{ component }}/src/{{ if component == 'framework' { 'athena' } else { 'athena-' + component } }}.cr

# Runs the test suite of the provided `component`, or `all` for all components, and watches for changes
[group('dev')]
watch-test component:
    watchexec --restart --watch=src/ --emit-events-to=none --clear -- {{ CRYSTAL }} spec src/components/{{ component }}/

# Runs the test suite of the provided `component`, defaulting to `all` components
[group('dev')]
test component='all':
    ./scripts/test.sh {{ component }}

# Runs the unit test suite of the provided `component`, defaulting to `all` components
[group('dev')]
test-unit component='all':
    @-echo {{ invocation_directory() / 'lib:' }}
    @echo {{ CRYSTAL }}
    @echo {{ shell( '$1 env CRYSTAL_PATH', CRYSTAL ) }}
    ./scripts/test.sh {{ component }} unit

# Runs the compiled test suite of the provided `component`, defaulting to `all` components
[group('dev')]
test-compiled component='all':
    ./scripts/test.sh {{ component }} compiled

# Runs all check related tasks
[group('check')]
lint: spellcheck format ameba

# Runs the Crystal formatter
[group('check')]
format:
    {{ CRYSTAL }} tool format

# Runs the Crystal formatter, fixing any issues
[group('check')]
format-fix:
    {{ CRYSTAL }} tool format --fix

# Runs `Ameba` static analysis
[group('check')]
ameba:
    ./bin/ameba

# Runs `typos` spellchecker
[group('check')]
spellcheck:
    typos

# Build the docs
[group('docs')]
build-docs: _mkdocs
    {{ MKDOCS }} build -d {{ OUTPUT_DIR }}

# Serve live-preview of the docs
[group('docs')]
serve-docs: _mkdocs
    {{ MKDOCS }} serve --open

# Clean MKDocs build artifacts
[group('docs')]
clean-docs:
    rm -rf {{ OUTPUT_DIR }}
    find src/components -type d -name "site" -exec rm -rf {} +

# Upgrade python deps
[group('administrative')]
upgrade: _pip
    {{ PIP_COMPILE }} -U requirements.in

# Clean build artifacts (.venv), and docs
[group('administrative')]
clean: clean-docs
    rm -rf .venv

_pip:
    python3 -m venv .venv
    {{ PIP }} install -q pip-tools

_mkdocs: _pip
    {{ PIP }} install -q -r requirements.txt
