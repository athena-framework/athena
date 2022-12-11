#!/usr/bin/env bash

EXIT_CODE=0
DEFAULT_OPTIONS=(-Dstrict_multi_assign --order=random --error-on-warnings)

# Runs the specs for all, or optionally a single component
#
# $1 - (optional) component to runs specs, or all if empty

if [ -n "$1" ]
then
  crystal spec "${DEFAULT_OPTIONS[@]}" "src/components/$1/spec"
  exit $?
fi

for component in $(find src/components/ -maxdepth 2 -type f -name shard.yml | xargs -I{} dirname {} | sort); do
  echo "::group::$component"
  crystal spec "${DEFAULT_OPTIONS[@]}" $component/spec || EXIT_CODE=1
  echo "::endgroup::"
done

exit $EXIT_CODE
