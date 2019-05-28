#!/bin/bash

if (( $# < 2 )); then
  SCRIPTFULLPATH=$( readlink -f "$BASH_SOURCE" )
  THIS=${SCRIPTFULLPATH##*/}
  echo "\
Export a docker image or container to an tar.lz file.

If a docker-image is provided, a temporary container will be created, 
exported and removed automatically.

Usage:
${THIS} <docker-image>|<docker-container> <export-file.tar.lz>

Example:
${THIS} docker/image:tag exported-docker-container.tar.lz
${THIS} container-name exported-docker-container.tar.lz
"
  exit
fi

DOCKER_SRC=$1
DOCKER_FILE=$2

if [[ $(docker image ls -q "${DOCKER_SRC}") ]]; then
  IS_IMAGE=true
  DOCKER_CONTAINER=docker-export-temp-container
  echo "Create temporary container for '${DOCKER_SRC}' ..."
  docker create --name ${DOCKER_CONTAINER} ${DOCKER_SRC}
else
  DOCKER_CONTAINER=${DOCKER_SRC}
fi

echo "Exporting '${DOCKER_SRC}' to '${DOCKER_FILE}' ..."
docker export ${DOCKER_CONTAINER} | pv | plzip --best -o ${DOCKER_FILE}

if [[ ${IS_IMAGE} ]]; then
  echo "Remove temporary container."
  docker container rm ${DOCKER_CONTAINER}
fi
