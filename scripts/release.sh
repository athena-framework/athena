#!/usr/bin/env bash

# $1 - Component to check for
# $2 - Branch to checkout (default: master)
function ensureRepoExists()
{
  local BRANCH=${2:-master}

  if [ ! -d "../$1" ]
  then
      git clone --quiet $URL "../$1" --branch $BRANCH
      cd "../$1"
  else
      cd "../$1"
      git checkout --quiet $BRANCH
      git fetch --quiet --tags
      git pull --quiet origin
  fi
}

# $1 - Component to bump
# $2 - Version to tag
function tag()
{
  declare -A componentNameMap
  componentNameMap[clock]=Clock
  componentNameMap[config]=Config
  componentNameMap[console]=Console
  componentNameMap[dependency-injection]="Dependency Injection"
  componentNameMap[dotenv]="Dotenv"
  componentNameMap[event-dispatcher]="Event Dispatcher"
  componentNameMap[mercure]=Mercure
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

  ensureRepoExists $1

  git tag -asm "$MESSAGE" $TAG
  git push --quiet origin $TAG

  printf "Tagged \e]8;;https://github.com/athena-framework/%s/releases/tag/%s\e\\%s\e]8;;\e\\ \n" $1 $TAG "$MESSAGE"

  cd $OLDPWD
}

# Helper script to assist in component release tasks
#
# tag     - Creates a signed git tag at the latest commit for the provided component(s). ./scripts/release.sh tag clock:0.1.0 console:0.4.0
# docPick - Cherry-picks a commit to the docs branch of the provided component. ./scripts/release.sh docPick dotenv abc123

METHOD=$1

case $METHOD in
  tag)
    # Support tagging multiple components at once
    for component in ${@:2}; do
      IFS=':' read -r name version <<< $component

      tag $name $version
    done
    ;;
  docPick)
    ensureRepoExists $2 docs

    git cherry-pick --quiet $3
    git push

    ;;
esac
