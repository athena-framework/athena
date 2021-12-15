#!/usr/bin/env bash
## Based on https://github.com/laravel/framework/blob/d1ef8e588cc7efc3b3cf925b42f134aa54a4f9c7/bin/split.sh

set -e
set -x

CURRENT_BRANCH="master"

function remote()
{
    git remote add $1 $2 || true
    git fetch $1
}

function split()
{
    git subtree push --prefix="$1" $2 $CURRENT_BRANCH
}

git pull origin $CURRENT_BRANCH

remote config https://github.com/athena-framework/config.git
remote console https://github.com/athena-framework/console.git
remote dependency-injection https://github.com/athena-framework/dependency-injection.git
remote event-dispatcher https://github.com/athena-framework/event-dispatcher.git
remote framework https://github.com/athena-framework/framework.git
remote negotiation https://github.com/athena-framework/negotiation.git
remote serializer https://github.com/athena-framework/serializer.git
remote spec https://github.com/athena-framework/spec.git
remote validator https://github.com/athena-framework/validator.git
remote website https://github.com/athena-framework/website.git

split "src/components/config" config
split "src/components/console" console
split "src/components/dependency_injection" dependency-injection
split "src/components/event_dispatcher" event-dispatcher
split "src/components/framework" framework
split "src/components/negotiation" negotiation
split "src/components/serializer" serializer
split "src/components/spec" spec
split "src/components/validator" validator
split "src/website" website
