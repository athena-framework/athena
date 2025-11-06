# Configuration

OUTPUT_DIR := './site'

# Binaries
# Scoped to the justfile so do not need to be exported

UV := 'uv'

# Needs to be exported so that the `spec` component can pick up on the customized $CRYSTAL env var.

export CRYSTAL := 'crystal'

_default:
    @just --list --unsorted

# Installs dev dependencies
[group('dev')]
install:
    SHARDS_OVERRIDE=shard.dev.yml shards update

# Runs and watches for changes to the main entrypoint file of the provided `component`
[group('dev')]
watch component:
    watchexec --restart --watch=src/ --emit-events-to=none --clear --no-project-ignore -- {{ CRYSTAL }} run src/components/{{ component }}/src/{{ if component == 'framework' { 'athena' } else { 'athena-' + component } }}.cr

# Runs the test suite of the provided `component`, or `all` for all components, and watches for changes
[group('dev')]
watch-test component:
    watchexec --restart --watch=src/ --emit-events-to=none --clear --no-project-ignore -- {{ CRYSTAL }} spec src/components/{{ component }}/

# Runs the test suite of the provided `component`, defaulting to `all` components
[group('dev')]
test component='all':
    ./scripts/test.sh {{ component }}

# Runs the unit test suite of the provided `component`, defaulting to `all` components
[group('dev')]
test-unit component='all':
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
build-docs: _uv _symlink_lib
    {{ UV }} run --frozen mkdocs build -d {{ OUTPUT_DIR }}

# Serve live-preview of the docs
[group('docs')]
serve-docs: _uv _symlink_lib
    {{ UV }} run --frozen mkdocs serve --open

# Clean MKDocs build artifacts
[group('docs')]
clean-docs:
    rm -rf {{ OUTPUT_DIR }}
    find src/components -type d -name "site" -exec rm -rf {} +

# Creates a new change file
[group('administrative')]
change:
    #!/usr/bin/env bash
    changie new \
      --custom Author="${CHANGIE_CUSTOM_AUTHOR}" \
      --custom Username="${CHANGIE_CUSTOM_USERNAME}"

# Batches change files for the provided *component* into a new intermdiary *version* file, defaulting to a `patch` release
[group('administrative')]
batch component version='patch':
    changie batch --project {{ component }} {{ version }}

# Merges/releases all pending intermdiary changelog files
[group('administrative')]
merge:
    changie merge

# Upgrade python deps
[group('administrative')]
upgrade: _uv
    {{ UV }} lock --upgrade

# Clean build artifacts (.venv), and docs
[group('administrative')]
clean: clean-docs
    rm -rf .venv

_uv:
    {{ UV }} sync --quiet --frozen

_symlink_lib:
    @ for component in $(find src/components/ -maxdepth 2 -type f -name shard.yml | xargs -I{} dirname {} | xargs -I{} basename {} | sort); do \
      ln --force --verbose --symbolic {{ (invocation_directory_native() / 'lib') }} "src/components/$component/lib"; \
    done
