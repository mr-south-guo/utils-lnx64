#!/bin/bash

if (( $# < 2 )); then
  SCRIPTFULLPATH=$( readlink -f "$BASH_SOURCE" )
  THIS=${SCRIPTFULLPATH##*/}
  echo "\
Import docker image from a tar.lz file.

The tar.lz file must be created by `docker export` and lzip compressed.
Recommend to use `docker-export.sh`.

Usage:
${THIS} <import-file.tar.lz> <image-name>

Example:
${THIS} exported-docker-container.tar.lz docker/image:tag
"
  exit
fi

DOCKER_FILE=$( readlink "$1")
DOCKER_IMAGE=$2

cat ${DOCKER_FILE} | plzip -d | pv | docker import - "${DOCKER_IMAGE}"
