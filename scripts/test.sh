#!/usr/bin/env bash

# Outputs the spec files of the provided shard that contain compiled specs.
# Building only these files when running compiled specs avoids building the rest of the specs that would not be ran anyway.
#
# $1 shard name
function compiledSpecFiles() (
  grep -rlE 'tags: "compiled"|Tags\("compiled"\)' --include="*.cr" "src/components/$1/spec" | sort
)

# $1 shard name
function runSpecs() (
  set -e
  SPEC_FILES="src/components/$1/spec"

  if [ "$SPEC_TYPE" == "compiled" ]
  then
    SPEC_FILES=$(compiledSpecFiles "$1")

    if [ -z "$SPEC_FILES" ]
    then
      echo "No compiled specs"
      exit 0
    fi
  fi

  $CRYSTAL spec "${DEFAULT_BUILD_OPTIONS[@]}" "${DEFAULT_OPTIONS[@]}" $SPEC_FILES
)

# Runtime coverage generation logic based on https://hannes.kaeufler.net/posts/measuring-code-coverage-in-crystal-with-kcov.
# Additionally generates a coverage report for unreachable code.
#
# Compiled time code generates a macro code coverage report for the entire shard, and each compiled sub-process spec.
#
# $1 shard name
function runSpecsWithCoverage() (
  set -e
  SHARD_NAME=$1
  SHARD_PATH="components/$SHARD_NAME"
  COVERAGE_BIN_PATH="./coverage/components/bin/$SHARD_NAME"

  rm -rf "./coverage/$SHARD_PATH"
  mkdir -p "./coverage/$SHARD_PATH" "./coverage/components/bin"

  # Entrypoint that covers the entire `spec/` directory.
  echo "require \"../../../src/$SHARD_PATH/spec/**\"" > "$COVERAGE_BIN_PATH.all.cr"

  # Build spec binary to run coverage against, which covers the entire `spec/` directory, or only the files containing compiled specs.
  if [ "$SPEC_TYPE" == "compiled" ]
  then
    for specFile in $(compiledSpecFiles "$SHARD_NAME"); do echo "require \"../../../$specFile\""; done > "$COVERAGE_BIN_PATH.cr"
  else
    cp "$COVERAGE_BIN_PATH.all.cr" "$COVERAGE_BIN_PATH.cr"
  fi

  if [ -s "$COVERAGE_BIN_PATH.cr" ]
  then
    $CRYSTAL build "${DEFAULT_BUILD_OPTIONS[@]}" "$COVERAGE_BIN_PATH.cr" -o "$COVERAGE_BIN_PATH" && \
    ATHENA_SPEC_COVERAGE_OUTPUT_DIR="$(realpath ./coverage/$SHARD_PATH/)" \
      kcov $(if $IS_CI != "true"; then echo "--cobertura-only"; fi) \
        --clean \
        --include-path="./src/$SHARD_PATH"\
        "./coverage/$SHARD_PATH"\
        "$COVERAGE_BIN_PATH"\
        --junit_output="./coverage/$SHARD_PATH/junit.xml"\
        "${DEFAULT_OPTIONS[@]}"
  else
    echo "No compiled specs"
  fi

  if [ "$SPEC_TYPE" != "unit" ]
  then
    # Generate macro coverage report.
    # The report itself is sent to STDOUT while other output is sent to STDERR.
    # We can ignore STDERR since those failures would be captured as part of running the specs themselves.
    $CRYSTAL tool macro_code_coverage --no-color "$COVERAGE_BIN_PATH.all.cr" > "./coverage/$SHARD_PATH/macro_coverage.root.codecov.json"
  fi

  # Only runtime code can be unreachable.
  if [ "$SPEC_TYPE" != "compiled" ]
  then
    $CRYSTAL tool unreachable --no-color --format=codecov "$COVERAGE_BIN_PATH.cr" > "./coverage/$SHARD_PATH/unreachable.codecov.json"
  fi
)

DEFAULT_BUILD_OPTIONS=(-Dstrict_multi_assign -Dpreview_overload_order --error-on-warnings)
DEFAULT_OPTIONS=(--order=random)
CRYSTAL=${CRYSTAL:=crystal}
HAS_KCOV=$(if command -v "kcov" &>/dev/null; then echo "true"; else echo "false"; fi)
IS_CI=${CI:="false"}
JOBS=${JOBS:=$(getconf _NPROCESSORS_ONLN)}

# Runs the specs for all, or optionally a single shard.
# Optionally generates code coverage report data as well.
#
# $1 - (optional) shard name to runs specs for, or "all". Defaults to "all".
# $2 - (optional) "type" of specs to run: "unit", "compiled", or "all". Defaults to "all".
#
# The JOBS env var controls how many shards run concurrently when running all shards. Defaults to the number of CPUs.

SHARD=${1-all}
SPEC_TYPE=${2-all}

if [ "$SPEC_TYPE" == "unit" ]
then
  DEFAULT_OPTIONS+=("--tag=~compiled")
elif [ "$SPEC_TYPE" == "compiled" ]
then
  DEFAULT_OPTIONS+=("--tag=compiled")
elif [ "$SPEC_TYPE" != "all" ]
then
  echo "Second argument must be 'unit', 'compiled', or 'all' got '${2}'."
  exit 1
fi

EXIT_CODE=0

if [ "$SHARD" != "all" ]
then
  if [ "$HAS_KCOV" = "true" ]
  then
    runSpecsWithCoverage "$SHARD"
  else
    runSpecs "$SHARD"
  fi
  exit $?
fi

# If we got this far we need to run specs for all shards
SHARD_PATHS=$(find src/ -maxdepth 3 -type f -name shard.yml | xargs -I{} dirname {} | sed 's|^src/||' | sort)

if [ "$JOBS" -gt 1 ]
then
  # Each shard runs via a separate invocation of this script with its output buffered to a log file.
  # The logs are printed in order once all shards have finished so that the output of each shard is not interleaved.
  LOG_DIR=$(mktemp -d)

  # Each shard uses its own cache dir since the compiler writes binaries to fixed paths within it, e.g. `crystal spec` always outputs `crystal-run-spec.tmp`.
  CACHE_DIR=$($CRYSTAL env CRYSTAL_CACHE_DIR)

  # The slowest shards are started first so they do not extend the total run time by starting after the others.
  SLOWEST_SHARDS="orm framework dependency_injection"

  {
    for name in $SLOWEST_SHARDS; do echo "$name"; done

    for shardPath in $SHARD_PATHS; do
      name=${shardPath#*/}
      [[ " $SLOWEST_SHARDS " == *" $name "* ]] || echo "$name"
    done
  } | \
    xargs -P "$JOBS" -I{} bash -c 'CRYSTAL_CACHE_DIR="$4/$1" "$0" "$1" "$2" > "$3/$1.log" 2>&1; echo $? > "$3/$1.status"; echo "Finished components/$1 with exit status $(cat "$3/$1.status")"' "$0" {} "$SPEC_TYPE" "$LOG_DIR" "$CACHE_DIR"

  for shardPath in $SHARD_PATHS; do
    name=${shardPath#*/}

    echo "::group::$shardPath"
    cat "$LOG_DIR/$name.log"
    echo "::endgroup::"

    if [ "$(cat "$LOG_DIR/$name.status")" -ne 0 ]; then
      EXIT_CODE=1
    fi
  done

  rm -rf "$LOG_DIR"
  exit $EXIT_CODE
fi

for shardPath in $SHARD_PATHS; do
  name=${shardPath#*/}

  echo "::group::$shardPath"

  if [ "$HAS_KCOV" = "true" ]
  then
    runSpecsWithCoverage "$name"
  else
    runSpecs "$name"
  fi

  if [ $? -ne 0 ]; then
    EXIT_CODE=1
  fi

  echo "::endgroup::"
done

exit $EXIT_CODE
