# Changes the directory into the provided component's git directory.
# Checks out the repo if it does not already exist.
# Be sure to change back to previous directory when done.
#
# $1 - Component to check for
# $2 - Branch to checkout (default: master)
# $3 - URL to use if component is not already cloned
function cdIntoComponent()
{
  local BRANCH=${2:-master}

  if [ ! -d "../$1" ]
  then
      git clone --quiet "$3" "../$1" --branch "$BRANCH"
      cd "../$1"
  else
      cd "../$1"
      git checkout --quiet "$BRANCH"
      git fetch --quiet --tags
      git pull --quiet origin "$BRANCH"
  fi
}
