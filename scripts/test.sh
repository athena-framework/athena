#!/usr/bin/env bash

# $1 component name
function runSpecs()
{
  $CRYSTAL spec "${DEFAULT_BUILD_OPTIONS[@]}" "${DEFAULT_OPTIONS[@]}" "src/components/$1/spec"
}

# $1 component name
function runSpecsWithCoverage()
{
  echo "require \"../../src/components/$1/spec/**\"" > "./coverage/bin/$1.cr" && \
  crystal build "${DEFAULT_BUILD_OPTIONS[@]}" "./coverage/bin/$1.cr" -o "./coverage/bin/$1" && \
  kcov --clean --cobertura-only --include-path="./src/components/$1/src" "./coverage/$1" "./coverage/bin/$1" --junit_output="./coverage/$1/junit.xml" "${DEFAULT_OPTIONS[@]}" || EXIT_CODE=1
}

DEFAULT_BUILD_OPTIONS=(-Dstrict_multi_assign -Dpreview_overload_order --error-on-warnings)
DEFAULT_OPTIONS=(--order=random)
CRYSTAL=${CRYSTAL:=crystal}
WITH_CODE_COVERAGE=${WITH_CODE_COVERAGE:=1}

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

# Coverage generation logic based on https://hannes.kaeufler.net/posts/measuring-code-coverage-in-crystal-with-kcov
mkdir -p coverage/bin
mkdir -p /tmp/athena/

if [ $COMPONENT != "all" ]
then
  if [ $WITH_CODE_COVERAGE == "1" ]
  then
    runSpecsWithCoverage $COMPONENT
  else
    runSpecs $COMPONENT
  fi
  exit $?
fi

for component in $(find src/components/ -maxdepth 2 -type f -name shard.yml | xargs -I{} dirname {} | xargs -I{} basename {} | sort); do
  echo "::group::$component"

  if [ $WITH_CODE_COVERAGE == "1" ]
  then
    runSpecsWithCoverage $component || EXIT_CODE=1
  else
    runSpecs $component
  fi

  echo "::endgroup::"
done

exit $EXIT_CODE
