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

# Helper script to assist in managing the mono/many-repos
#
# sync    - Syncs the monorepo out to the many-repos. ./scripts/repo.sh sync
# subtree - Initialize a new subtree repo. ./scripts/repo.sh subtree test 'Add the `example` component' src/components/test

METHOD=$1

case $METHOD in
  sync)
    maybeSync "src/components/clock" clock https://github.com/athena-framework/clock.git
    maybeSync "src/components/console" console https://github.com/athena-framework/console.git
    maybeSync "src/components/dependency_injection" dependency-injection https://github.com/athena-framework/dependency-injection.git
    maybeSync "src/components/dotenv" dotenv https://github.com/athena-framework/dotenv.git
    maybeSync "src/components/event_dispatcher" event-dispatcher https://github.com/athena-framework/event-dispatcher.git
    maybeSync "src/components/image_size" image-size https://github.com/athena-framework/image-size.git
    maybeSync "src/components/framework" framework https://github.com/athena-framework/framework.git
    maybeSync "src/components/mercure" mercure https://github.com/athena-framework/mercure.git
    maybeSync "src/components/negotiation" negotiation https://github.com/athena-framework/negotiation.git
    maybeSync "src/components/routing" routing https://github.com/athena-framework/routing.git
    maybeSync "src/components/serializer" serializer https://github.com/athena-framework/serializer.git
    maybeSync "src/components/spec" spec https://github.com/athena-framework/spec.git
    maybeSync "src/components/validator" validator https://github.com/athena-framework/validator.git

    ;;
  subtree)
    # $2 - Name of the `athena-framework` GH repo to subtree
    # $3 - Commit message
    # $4 - Path to target directory
    git subtree add --squash --message="'$3'" --prefix="$4" "https://github.com/athena-framework/$2.git" master

    ;;
esac
