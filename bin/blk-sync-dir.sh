#!/bin/bash

if (( $# < 3 )); then
  SCRIPTFULLPATH=$( readlink -f "$BASH_SOURCE" )
  THIS=${SCRIPTFULLPATH##*/}
  echo "\
Block-Sync specified files in two directorys recursively.

Usage:
${THIS} <find-pattern> <source-dir> <destination-dir>

Example:
${THIS} *.btrfs /source/dir /dest/dir
"
  exit
fi

FIND_PATTERN=$1
SRC_DIR=$2
DEST_DIR=$3

CUR_DIR=$( pwd )
cd "${SRC_DIR}"
for f in $( find . -type f -name "${FIND_PATTERN}" ); do
  SRC_FILE=$( readlink -f "${SRC_DIR}/$f" )
  DEST_FILE=$( readlink -f "${DEST_DIR}/$f" )
  blk-sync-file.sh -s "${SRC_FILE}" -d "${DEST_FILE}"
done
cd "${CUR_DIR}"
