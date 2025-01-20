#!/usr/bin/env bash

# $1 component name
function runSpecs() (
  set -e
  $CRYSTAL spec "${DEFAULT_BUILD_OPTIONS[@]}" "${DEFAULT_OPTIONS[@]}" "src/components/$1/spec"
)

# Coverage generation logic based on https://hannes.kaeufler.net/posts/measuring-code-coverage-in-crystal-with-kcov
#
# $1 component name
function runSpecsWithCoverage() (
  mkdir -p coverage/bin "coverage/$1"
  echo "require \"../../src/components/$1/spec/**\"" > "./coverage/bin/$1.cr" && \
  $CRYSTAL build "${DEFAULT_BUILD_OPTIONS[@]}" "./coverage/bin/$1.cr" -o "./coverage/bin/$1" && \

  # Run this first so spec failures are reported as an error.
  if [ $TYPE != "compiled" ]
  then
    $CRYSTAL tool unreachable --format=codecov "./coverage/bin/$1.cr" > "./coverage/$1/unreachable.codecov.json"
  fi

  kcov $(if $IS_CI != "true"; then echo "--cobertura-only"; fi) --clean --include-path="./src/components/$1" "./coverage/$1" "./coverage/bin/$1" --junit_output="./coverage/$1/junit.xml" "${DEFAULT_OPTIONS[@]}"
)

DEFAULT_BUILD_OPTIONS=(-Dstrict_multi_assign -Dpreview_overload_order --error-on-warnings)
DEFAULT_OPTIONS=(--order=random)
CRYSTAL=${CRYSTAL:=crystal}
HAS_KCOV=$(if command -v "kcov" &>/dev/null; then echo "true"; else echo "false"; fi)
IS_CI=${CI:="false"}

# Runs the specs for all, or optionally a single component.
# Optionally generates code coverage report data as well.
#
# $1 - (optional) component name to runs specs for, or "all". Defaults to "all".
# $2 - (optional) "type" of specs to run: "unit", "compiled", or "all". Defaults to "all".

COMPONENT=${1-all}
TYPE=${2-all}

if [ $TYPE == "unit" ]
then
  DEFAULT_OPTIONS+=("--tag=~compiled")
elif [ $TYPE == "compiled" ]
then
  DEFAULT_OPTIONS+=("--tag=compiled")
elif [ $TYPE != "all" ]
then
  echo "Second argument must be 'unit', 'compiled', or 'all' got '${2}'."
  exit 1
fi

EXIT_CODE=0

if [ $COMPONENT != "all" ]
then
  if [ $HAS_KCOV = "true" ]
  then
    runSpecsWithCoverage $COMPONENT
  else
    runSpecs $COMPONENT
  fi
  exit $?
fi

for component in $(find src/components/ -maxdepth 2 -type f -name shard.yml | xargs -I{} dirname {} | xargs -I{} basename {} | sort); do
  echo "::group::$component"

  if [ $HAS_KCOV = "true" ]
  then
    runSpecsWithCoverage $component
  else
    runSpecs $component
  fi

  if [ $? -eq 1 ]; then
    EXIT_CODE=1
  fi

  echo "::endgroup::"
done

exit $EXIT_CODE
