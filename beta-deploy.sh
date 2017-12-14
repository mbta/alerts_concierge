#!/usr/bin/env bash

# avoid common bash errors
set -o nounset
set -o errexit

# current workdir should be the project root
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $PROJECT_DIR

# constants
DOCKER_BUILD_TAG=build-alert-platform
DOCKER_FILE_NAME=docker/Dockerfile.build.alert_platform
RELEASE_DIR=apps/concierge_site/.deliver/releases
MIX_VERSION_NUMBER=$(grep -o 'version: .*"' apps/concierge_site/mix.exs | grep -E -o '([0-9]+\.)+[0-9]+')

# build the docker image if necessary
if [[ "$(docker images -q ${DOCKER_BUILD_TAG}:latest 2> /dev/null)" == "" ]]; then
  echo ">> BUILD FIRST DOCKER IMAGE"
  docker build --tag=$DOCKER_BUILD_TAG -f $DOCKER_FILE_NAME .
fi

# start a docker instance and get its ID
DOCKER_CONTAINER_ID=$(docker run -t -d ${DOCKER_BUILD_TAG} /bin/bash)

# build the latest version
echo ">> NEW RELEASE BUILD"
docker build --tag=$DOCKER_BUILD_TAG -f $DOCKER_FILE_NAME .

# copy the build from the container to the host file system
mkdir -p $RELEASE_DIR
docker cp \
$DOCKER_CONTAINER_ID:/alerts_concierge/releases/concierge_site/releases/$MIX_VERSION_NUMBER/concierge_site.tar.gz \
$RELEASE_DIR/concierge_site_$MIX_VERSION_NUMBER.tar.gz

# kill the docker build container
docker kill $DOCKER_CONTAINER_ID

# go the the concierge_site directory
cd apps/concierge_site

# edilver commands to ship release to remove server
mix edeliver deploy release to staging
mix edeliver stop staging
mix edeliver start staging
mix edeliver ping staging

# github release tag
# git tag -a with_edeliver -m "Setup edeliver and distillery"
# git push origin --tags
