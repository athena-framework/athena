#!/usr/bin/env bash

DEFAULT_OPTIONS=(-Dstrict_multi_assign -Dpreview_overload_order --order=random --error-on-warnings)
CRYSTAL=${CRYSTAL:=crystal}

# Runs the specs for all, or optionally a single component
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

if [ $COMPONENT != "all" ]
then
  $CRYSTAL spec "${DEFAULT_OPTIONS[@]}" "src/components/$1/spec"
  exit $?
fi

EXIT_CODE=0

for component in $(find src/components/ -maxdepth 2 -type f -name shard.yml | xargs -I{} dirname {} | sort); do
  echo "::group::$component"
  $CRYSTAL spec "${DEFAULT_OPTIONS[@]}" $component/spec || EXIT_CODE=1
  echo "::endgroup::"
done

exit $EXIT_CODE
