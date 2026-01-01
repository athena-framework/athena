# Configuration

OUTPUT_DIR := './site'

# Binaries
# Scoped to the justfile so do not need to be exported

UV := 'uv'

# Needs to be exported so that the `spec` component can pick up on the customized $CRYSTAL env var.

export CRYSTAL := 'crystal'

_default:
    @just --list --unsorted

# Installs Crystal shard dependencies
[group('dev')]
install:
    SHARDS_OVERRIDE=shard.dev.yml shards update

# Run shard entrypoint with live reload
[group('dev')]
watch shard type='component':
    watchexec --restart --watch=src/ --emit-events-to=none --clear --no-project-ignore -- {{ CRYSTAL }} run src/{{ type }}s/{{ shard }}/src/{{ if shard == 'framework' { 'athena' } else { 'athena-' + shard } }}.cr

# Run tests with live reload
[group('dev')]
watch-test shard type='component':
    watchexec --restart --watch=src/ --emit-events-to=none --clear --no-project-ignore -- {{ CRYSTAL }} spec src/{{ type }}s/{{ shard }}/

# Run test suite; `type` is ignored when running test suite for all shards
[group('dev')]
test shard='all' type='component':
    ./scripts/test.sh {{ shard }} all {{ type }}

# Run unit tests only; `type` is ignored when running test suite for all shards
[group('dev')]
test-unit shard='all' type='component':
    ./scripts/test.sh {{ shard }} unit {{ type }}

# Run compiled tests only; `type` is ignored when running test suite for all shards
[group('dev')]
test-compiled shard='all' type='component':
    ./scripts/test.sh {{ shard }} compiled {{ type }}

# Run all linters (format + ameba + spellcheck)
[group('check')]
lint: spellcheck format ameba

# Check Crystal formatting
[group('check')]
format:
    {{ CRYSTAL }} tool format

# Fix Crystal formatting issues
[group('check')]
format-fix:
    {{ CRYSTAL }} tool format --fix

# Run Ameba static analysis
[group('check')]
ameba:
    ./bin/ameba

# Run typos spellchecker
[group('check')]
spellcheck:
    typos

# Build the docs
[group('docs')]
build-docs: _symlink_lib
    {{ UV }} run --frozen mkdocs build -d {{ OUTPUT_DIR }}

# Serve live-preview of the docs
[group('docs')]
serve-docs: _symlink_lib
    {{ UV }} run --frozen mkdocs serve --livereload

# Clean MkDocs build artifacts
[group('docs')]
clean-docs:
    rm -rf {{ OUTPUT_DIR }}
    find src/ -type d -name "site" -exec rm -rf {} +

# Create a new change file
[group('administrative')]
change:
    #!/usr/bin/env bash
    changie new \
      --custom Author="${CHANGIE_CUSTOM_AUTHOR}" \
      --custom Username="${CHANGIE_CUSTOM_USERNAME}"

# Batch change files into a version changelog
[group('administrative')]
batch project version='patch':
    changie batch --project {{ project }} {{ version }}

# Merge pending changelogs into CHANGELOG.md
[group('administrative')]
merge:
    changie merge

# Upgrade Python dependencies
[group('administrative')]
upgrade:
    {{ UV }} lock --upgrade

# Clean build artifacts and docs
[group('administrative')]
clean: clean-docs
    rm -rf .venv

_symlink_lib:
    @ for shardDir in $(find src/ -maxdepth 3 -type f -name shard.yml | xargs -I{} dirname {} | sort); do \
      ln --force --verbose --symbolic {{ (invocation_directory_native() / 'lib') }} "$shardDir/lib"; \
    done
