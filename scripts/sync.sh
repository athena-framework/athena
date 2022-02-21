#!/usr/bin/env bash
## Based on https://github.com/laravel/framework/blob/d1ef8e588cc7efc3b3cf925b42f134aa54a4f9c7/bin/split.sh

set -e

CURRENT_BRANCH="master"

# Syncs the provided component if changes were made within the provided sub directory
#
# $1 - Sub directory path
# $2 - Component name
# $3 - Git URL
function maybeSync()
{
  if ! $(git diff --quiet --exit-code $BEFORE_SHA $AFTER_SHA -- $1); then
    echo "::group::Syncing $1"
    git remote add $2 $3 || true
    git fetch $2
    git subtree push --prefix="$1" $2 $CURRENT_BRANCH
    echo "::endgroup::"
  fi
}

maybeSync "src/components/config" config https://github.com/athena-framework/config.git
maybeSync "src/components/console" console https://github.com/athena-framework/console.git
maybeSync "src/components/dependency_injection" dependency-injection https://github.com/athena-framework/dependency-injection.git
maybeSync "src/components/event_dispatcher" event-dispatcher https://github.com/athena-framework/event-dispatcher.git
maybeSync "src/components/image_size" image-size https://github.com/athena-framework/image-size.git
maybeSync "src/components/framework" framework https://github.com/athena-framework/framework.git
maybeSync "src/components/negotiation" negotiation https://github.com/athena-framework/negotiation.git
maybeSync "src/components/routing" routing https://github.com/athena-framework/routing.git
maybeSync "src/components/serializer" serializer https://github.com/athena-framework/serializer.git
maybeSync "src/components/spec" spec https://github.com/athena-framework/spec.git
maybeSync "src/components/validator" validator https://github.com/athena-framework/validator.git
# maybeSync "src/website" website https://github.com/athena-framework/website.git
