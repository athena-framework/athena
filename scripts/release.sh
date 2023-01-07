#!/usr/bin/env bash

# $1 - Component to bump
# $2 - Version to tag - A branch for the major.minor will be created if it does not already exist
function tag() 
{
  declare -A componentNameMap
  componentNameMap[config]=Config
  componentNameMap[console]=Console
  componentNameMap[dependency-injection]="Dependency Injection"
  componentNameMap[event-dispatcher]="Event Dispatcher"
  componentNameMap[framework]=Framework
  componentNameMap[image-size]="Image Size"
  componentNameMap[negotiation]=Negotiation
  componentNameMap[routing]=Routing
  componentNameMap[serializer]=Serializer
  componentNameMap[spec]=Spec
  componentNameMap[validator]=Validator

  VERSION="$2"
  VERSION="${VERSION#[vV]}"
  VERSION_MAJOR="${VERSION%%\.*}"
  VERSION_MINOR="${VERSION#*.}"
  VERSION_MINOR="${VERSION_MINOR%.*}"
  VERSION_PATCH="${VERSION##*.}"

  URL=https://github.com/athena-framework/$1
  BRANCH="release/$VERSION_MAJOR.$VERSION_MINOR"
  TAG="v$2"
  MESSAGE="Athena ${componentNameMap[$1]} $2"

  if [ ! -d "../$1" ]
  then
      git clone --quiet $URL "../$1"
      cd "../$1"
  else
      cd "../$1"
      git checkout --quiet master
      git fetch --quiet --tags
      git pull --quiet origin
  fi

  if ! git show-ref --quiet "refs/heads/$BRANCH"; then
    git branch --quiet $BRANCH
    git push --quiet origin $BRANCH &> /dev/null
  fi

  git checkout --quiet $BRANCH
  git pull --quiet origin $BRANCH

  git tag -a -s -m "$MESSAGE" $TAG
  git push --quiet origin $TAG

  git checkout --quiet master

  printf "Tagged \e]8;;https://github.com/athena-framework/%s/releases/tag/%s\e\\%s\e]8;;\e\\" $1 $TAG "$MESSAGE"

  cd $OLDPWD
}

# Helper script to assist in component releases
#
# tag - Creates a signed git tag at the latest commit for the provided component.

METHOD=$1

case $METHOD in
  tag)
    tag $2 $3
    ;;
esac
