#!/usr/bin/env bash

# Displays the current version and commits since last version
#
# $1 - Component name
function diff()
{
    URL=https://github.com/athena-framework/$1

    if [ ! -d "../$1" ]
    then
        git clone --quiet $URL "../$1"
        cd "../$1"
    else
        cd "../$1"
        git fetch --quiet --tags
        git pull --quiet origin master
    fi

    LATEST_TAG=$(git tag --sort=v:refname | tail -n1)

    git diff --quiet $LATEST_TAG..master

    if [ 1 == $? ]
    then
        printf "============\n$1: \e]8;;%s/compare/%s...master\e\\%s\e]8;;\e\\  \n" $URL $LATEST_TAG $LATEST_TAG

        git log --pretty="  %h %s%b" $LATEST_TAG..master | sed "s/)\*/)\n    \*/" | sed 's/^\*/    \*/'
    fi

    cd $OLDPWD
}

if [ -n "$1" ]
then
  diff $1
  exit $?
fi

diff clock
diff console
diff dependency-injection
diff dotenv
diff event-dispatcher
diff image-size
diff mercure
diff mime
diff framework
diff negotiation
diff routing
diff serializer
diff spec
diff validator
