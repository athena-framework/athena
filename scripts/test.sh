#!/usr/bin/env bash

# $1 shard name
# $2 shard type
function runSpecs() (
  set -e
  $CRYSTAL spec "${DEFAULT_BUILD_OPTIONS[@]}" "${DEFAULT_OPTIONS[@]}" "src/$2/$1/spec"
)

# Runtime coverage generation logic based on https://hannes.kaeufler.net/posts/measuring-code-coverage-in-crystal-with-kcov.
# Additionally generates a coverage report for unreachable code.
#
# Compiled time code generates a macro code coverage report for the entire shard, and each compiled sub-process spec.
#
# $1 shard name
# $2 shard type
function runSpecsWithCoverage() (
  set -e
  SHARD_NAME=$1
  SHARD_TYPE=$2
  SHARD_PATH="$SHARD_TYPE/$SHARD_NAME"
  COVERAGE_BIN_PATH="./coverage/$SHARD_TYPE/bin/$SHARD_NAME"

  rm -rf "./coverage/$SHARD_PATH"
  mkdir -p "./coverage/$SHARD_PATH" "./coverage/$SHARD_TYPE/bin"

  # Build spec binary that covers entire `spec/` directory to run coverage against.
  echo "require \"../../../src/$SHARD_PATH/spec/**\"" > "$COVERAGE_BIN_PATH.cr" && \
  $CRYSTAL build "${DEFAULT_BUILD_OPTIONS[@]}" "$COVERAGE_BIN_PATH.cr" -o "$COVERAGE_BIN_PATH" && \
  ATHENA_SPEC_COVERAGE_OUTPUT_DIR="$(realpath ./coverage/$SHARD_PATH/)" \
    kcov $(if $IS_CI != "true"; then echo "--cobertura-only"; fi) \
      --clean \
      --include-path="./src/$SHARD_PATH"\
      "./coverage/$SHARD_PATH"\
      "$COVERAGE_BIN_PATH"\
      --junit_output="./coverage/$SHARD_PATH/junit.xml"\
      "${DEFAULT_OPTIONS[@]}"

  if [ "$SPEC_TYPE" != "unit" ]
  then
    # Generate macro coverage report.
    # The report itself is sent to STDOUT while other output is sent to STDERR.
    # We can ignore STDERR since those failures would be captured as part of running the specs themselves.
    $CRYSTAL tool macro_code_coverage --no-color "$COVERAGE_BIN_PATH.cr" > "./coverage/$SHARD_PATH/macro_coverage.root.codecov.json"
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
# $3 - (optional) "type" of the shard: "component", "bundle". Defaults to "component".

SHARD=${1-all}
SPEC_TYPE=${2-all}
SHARD_TYPE=${3-component}s

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
    runSpecsWithCoverage "$SHARD" "$SHARD_TYPE"
  else
    runSpecs "$SHARD" "$SHARD_TYPE"
  fi
  exit $?
fi

# If we got this far we need to run specs for all shards, so cannot just rely on `$SHARD_TYPE`
for shardPath in $(find src/ -maxdepth 3 -type f -name shard.yml | xargs -I{} dirname {} | sed 's|^src/||' | sort); do
  type=${shardPath%/*}
  name=${shardPath#*/}

  echo "::group::$shardPath"

  if [ "$HAS_KCOV" = "true" ]
  then
    runSpecsWithCoverage "$name" "$type"
  else
    runSpecs "$name" "$type"
  fi

  if [ $? -eq 1 ]; then
    EXIT_CODE=1
  fi

  echo "::endgroup::"
done

exit $EXIT_CODE
