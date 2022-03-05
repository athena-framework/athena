#!/usr/bin/env bash

EXIT_CODE=0

for component in $(find src/components/ -maxdepth 2 -type f -name shard.yml | xargs -I{} dirname {} | sort); do
  echo "::group::$component"
  crystal spec -Dstrict_multi_assign $component/spec --order random --error-on-warnings --exclude-warnings $component/spec || EXIT_CODE=1
  echo "::endgroup::"
done

exit $EXIT_CODE
