#!/bin/bash

set -e -x

PREFIX=apps
ALERT_APP=alert_processor
CONCIERGE_APP=concierge_site
BUILD_TAG=build-alert-platform
CONTAINER=$(docker run -d ${BUILD_TAG} /bin/bash sleep 2000)
DOCKER_FILE_NAME=docker/Dockerfile.build.alert_platform
ALERT_VERSION_NUMBER=$(grep -o 'version: .*"' ${PREFIX}/${ALERT_APP}/mix.exs | grep -E -o '([0-9]+\.)+[0-9]+')
CONCIERGE_VERSION_NUMBER=$(grep -o 'version: .*"' ${PREFIX}/${CONCIERGE_APP}/mix.exs | grep -E -o '([0-9]+\.)+[0-9]+')

docker build --tag=$BUILD_TAG -f $DOCKER_FILE_NAME .

docker cp\
$CONTAINER:/alerts_concierge/releases/$ALERT_APP/releases/$ALERT_VERSION_NUMBER/$ALERT_APP.tar.gz\
$PREFIX/$ALERT_APP/.deliver/releases/${ALERT_APP}_$ALERT_VERSION_NUMBER.tar.gz

docker cp\
$CONTAINER:/alerts_concierge/releases/$CONCIERGE_APP/releases/$CONCIERGE_VERSION_NUMBER/$CONCIERGE_APP.tar.gz\
$PREFIX/$CONCIERGE_APP/.deliver/releases/${CONCIERGE_APP}_$CONCIERGE_VERSION_NUMBER.tar.gz

docker kill $CONTAINER
