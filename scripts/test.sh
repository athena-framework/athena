#!/usr/bin/env bash

# Outputs the spec files of the provided shard that contain compiled specs.
# Building only these files when running compiled specs avoids building the rest of the specs that would not be ran anyway.
# Any `"compiled"` string literal matches so that no compiled spec is skipped, whichever way it is tagged, at the cost of sometimes building an extra file.
#
# $1 shard name
function compiledSpecFiles() (
  grep -rl '"compiled"' --include="*.cr" "src/components/$1/spec" | sort
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
    # kcov's shared library support preloads a library into every process the specs spawn, such as the compiler for compiled specs, which stops each of them at startup.
    # `--skip-solibs` avoids that, but kcov then can't locate a position independent binary in memory, so the binary is built without PIE.
    $CRYSTAL build "${DEFAULT_BUILD_OPTIONS[@]}" --link-flags=-no-pie "$COVERAGE_BIN_PATH.cr" -o "$COVERAGE_BIN_PATH" && \
    ATHENA_SPEC_COVERAGE_OUTPUT_DIR="$(realpath ./coverage/$SHARD_PATH/)" \
      kcov $(if $IS_CI != "true"; then echo "--cobertura-only"; fi) \
        --skip-solibs \
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

# Runs the specs for all, or optionally a single shard.
# Optionally generates code coverage report data as well.
#
# $1 - (optional) shard name to runs specs for, or "all". Defaults to "all".
# $2 - (optional) "type" of specs to run: "unit", "compiled", or "all". Defaults to "all".

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
for shardPath in $(find src/ -maxdepth 3 -type f -name shard.yml | xargs -I{} dirname {} | sed 's|^src/||' | sort); do
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
