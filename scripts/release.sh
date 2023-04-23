#!/usr/bin/env bash

# $1 - Component to bump
# $2 - Version to tag
function tag()
{
  declare -A componentNameMap
  componentNameMap[config]=Config
  componentNameMap[console]=Console
  componentNameMap[dependency-injection]="Dependency Injection"
  componentNameMap[dotenv]="Dotenv"
  componentNameMap[event-dispatcher]="Event Dispatcher"
  componentNameMap[framework]=Framework
  componentNameMap[image-size]="Image Size"
  componentNameMap[negotiation]=Negotiation
  componentNameMap[routing]=Routing
  componentNameMap[serializer]=Serializer
  componentNameMap[spec]=Spec
  componentNameMap[validator]=Validator

  URL=https://github.com/athena-framework/$1
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

  git tag -asm "$MESSAGE" $TAG
  git push --quiet origin $TAG

  printf "Tagged \e]8;;https://github.com/athena-framework/%s/releases/tag/%s\e\\%s\e]8;;\e\\" $1 $TAG "$MESSAGE"

  cd $OLDPWD
}

# Helper script to assist in component releases
#
# tag - Creates a signed git tag at the latest commit for the provided component(s).

METHOD=$1

case $METHOD in
  tag)
    # Support tagging multiple components at once
    for component in ${@:2}; do
      IFS=':' read -r name version <<< $component

      tag $name $version
    done
    ;;
esac
