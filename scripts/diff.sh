#!/usr/bin/env bash

# Syncs the provided component if changes were made within the provided sub directory
#
# $1 - Component name
# $2 - Git URL
function diff()
{
    if [ ! -d "../$1" ]
    then
        git clone --quiet $2 "../$1"
        cd "../$1"
    else
        cd "../$1"
        git pull --quiet origin master
    fi

    LATEST_TAG=$(git tag --sort=v:refname | tail -n1)

    git diff --quiet $LATEST_TAG..master

    if [ 1 == $? ]
    then
        echo "============"
        echo "$1: $LATEST_TAG"
        git log --oneline $LATEST_TAG..master | sed 's/^/  /'
    fi

    cd $OLDPWD
}

diff config https://github.com/athena-framework/config.git
diff console https://github.com/athena-framework/console.git
diff dependency-injection https://github.com/athena-framework/dependency-injection.git
diff event-dispatcher https://github.com/athena-framework/event-dispatcher.git
diff image-size https://github.com/athena-framework/image-size.git
diff framework https://github.com/athena-framework/framework.git
diff negotiation https://github.com/athena-framework/negotiation.git
diff routing https://github.com/athena-framework/routing.git
diff serializer https://github.com/athena-framework/serializer.git
diff spec https://github.com/athena-framework/spec.git
diff validator https://github.com/athena-framework/validator.git
