#!/usr/bin/env bash
## Based on https://github.com/laravel/framework/blob/d1ef8e588cc7efc3b3cf925b42f134aa54a4f9c7/bin/split.sh

set -e

DEFAULT_BRANCH="master"

. ./scripts/_common.sh

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
    git subtree push --prefix="$1" $2 $DEFAULT_BRANCH

    # Sync the newly pushed commit on the component repo to the `docs` branch for this component.
    if [[ $UPDATE_DOCS == "1" ]]; then
      NEW_COMMIT=$(git ls-remote $3 HEAD | awk '{ print $1}')
      cdIntoComponent $2 docs $3
      git cherry-pick $NEW_COMMIT
      git push
      CD $OLDPWD
    fi

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
    maybeSync "src/components/clock" clock git@github.com:athena-framework/clock.git
    maybeSync "src/components/console" console git@github.com:athena-framework/console.git
    maybeSync "src/components/contracts" contracts git@github.com:athena-framework/contracts.git
    maybeSync "src/components/dependency_injection" dependency-injection git@github.com:athena-framework/dependency-injection.git
    maybeSync "src/components/dotenv" dotenv git@github.com:athena-framework/dotenv.git
    maybeSync "src/components/event_dispatcher" event-dispatcher git@github.com:athena-framework/event-dispatcher.git
    maybeSync "src/components/image_size" image-size git@github.com:athena-framework/image-size.git
    maybeSync "src/components/framework" framework git@github.com:athena-framework/framework.git
    maybeSync "src/components/mercure" mercure git@github.com:athena-framework/mercure.git
    maybeSync "src/components/mime" mime git@github.com:athena-framework/mime.git
    maybeSync "src/components/negotiation" negotiation git@github.com:athena-framework/negotiation.git
    maybeSync "src/components/routing" routing git@github.com:athena-framework/routing.git
    maybeSync "src/components/serializer" serializer git@github.com:athena-framework/serializer.git
    maybeSync "src/components/spec" spec git@github.com:athena-framework/spec.git
    maybeSync "src/components/validator" validator git@github.com:athena-framework/validator.git

    # Re-build the docs if we updated any `docs` branches
    if [[ $UPDATE_DOCS == "1" ]]; then
      gh workflow run release.yml
    fi

    ;;
  subtree)
    # $2 - Name of the `athena-framework` GH repo to subtree
    # $3 - Commit message
    # $4 - Path to target directory
    git subtree add --squash --message="'$3'" --prefix="$4" "https://github.com/athena-framework/$2.git" master

    ;;
esac
