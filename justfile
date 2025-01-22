# Configuration

OUTPUT_DIR := './site'
DEFAULT_BUILD_OPTIONS := '-Dstrict_multi_assign -Dpreview_overload_order --error-on-warnings'
DEFAULT_OPTIONS := '--order=random'

# Binaries

CRYSTAL := 'crystal'
KCOV := `command -v 'kcovv' || echo ''`
MKDOCS := './.venv/bin/mkdocs'
PIP := './.venv/bin/pip3'
PIP_COMPILE := './.venv/bin/pip-compile'

# Ensure when MkDocs is generating the docs for each component it's able to find their shard dependencies
# via the monorepo's `lib/` dir versus `src/components/<name>/lib` which doesn't exist.

export CRYSTAL_PATH := invocation_directory() + '/lib:' + `crystal env CRYSTAL_PATH`

_default:
    @just --list --unsorted

# Runs and watches for changes to the main entrypoint file of the provided `component`
[group('dev')]
watch component:
    watchexec --restart --watch=src/ --emit-events-to=none --clear -- crystal run src/components/{{ component }}/src/athena-{{ component }}.cr

# Runs the test suite of the provided `component`, or `all` for all components
[group('dev')]
@test component:
    echo {{ foo }}

#     just _test-{{ if KCOV != '' { 'with-coverage' } else { 'without-coverage' } }} {{ component }}

foo := '-type'

_test-with-coverage component:
    echo 'with kcov'

_test-without-coverage component:
    {{ CRYSTAL }} spec {{ DEFAULT_BUILD_OPTIONS }} {{ DEFAULT_OPTIONS }} "src/components/{{ component }}/spec"

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
