#!/usr/bin/env bash

. ./scripts/_common.sh

# $1 - Component to bump
# $2 - Version to tag
function tag()
{
  declare -A componentNameMap
  componentNameMap[clock]=Clock
  componentNameMap[console]=Console
  componentNameMap[contracts]=Contracts
  componentNameMap[dependency-injection]="Dependency Injection"
  componentNameMap[dotenv]="Dotenv"
  componentNameMap[event-dispatcher]="Event Dispatcher"
  componentNameMap[mercure]=Mercure
  componentNameMap[mime]=MIME
  componentNameMap[framework]=Framework
  componentNameMap[image-size]="Image Size"
  componentNameMap[negotiation]=Negotiation
  componentNameMap[routing]=Routing
  componentNameMap[serializer]=Serializer
  componentNameMap[spec]=Spec
  componentNameMap[validator]=Validator

  local URL="git@github.com:athena-framework/$1.git"
  local TAG="v$2"
  local MESSAGE="Athena ${componentNameMap[$1]} $2"

  cdIntoComponent $1

  git tag -asm "$MESSAGE" $TAG
  git push --quiet origin $TAG

  # Be sure to reset `docs` branch back to current state of `master` as a release assumes the previously cherry-picked commits are now inherently included
  git branch --quiet --force docs master
  git push --quiet origin docs --force

  printf "Tagged \e]8;;https://github.com/athena-framework/%s/releases/tag/%s\e\\%s\e]8;;\e\\ \n" $1 $TAG "$MESSAGE"

  cd $OLDPWD
}

# Helper script to assist in component release tasks
#
# tag       - Creates a signed git tag at the latest commit for the provided component(s). ./scripts/release.sh tag clock:0.1.0 console:0.4.0

METHOD=$1

case $METHOD in
  tag)
    # Support tagging multiple components at once
    for component in ${@:2}; do
      IFS=':' read -r name version <<< $component

      tag $name $version
    done

    # Re-build the docs after tagging every component
    gh workflow run release.yml
    ;;
esac
