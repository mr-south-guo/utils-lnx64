#!/bin/bash

if (( $# < 2 )); then
  SCRIPTFULLPATH=$( readlink -f "$BASH_SOURCE" )
  THIS=${SCRIPTFULLPATH##*/}
  echo "\
Resize btrfs loop back file.

Usage:
${THIS} <btrfs-file> <new-size>

Example:
${THIS} file.btrfs 3G
"
  exit
fi

BTRFS_FILE=$1
NEW_SIZE=$2
TEMP_MOUNT_POINT=/tmp/.mount-${BTRFS_FILE}
OLD_SIZE=$( numfmt --to=iec $(stat -c "%s" ${BTRFS_FILE}) )

if (( $(stat -c "%s" ${BTRFS_FILE}) < $(numfmt --from=iec ${NEW_SIZE}) )); then
  echo "Expanding '${BTRFS_FILE}' from ${OLD_SIZE} to ${NEW_SIZE} ..."
  truncate -s ${NEW_SIZE} ${BTRFS_FILE}
  sudo mkdir -p ${TEMP_MOUNT_POINT}
  sudo mount ${BTRFS_FILE} ${TEMP_MOUNT_POINT} -o rw,noatime
  sudo btrfs filesystem resize max ${TEMP_MOUNT_POINT}
  df -h ${TEMP_MOUNT_POINT}
  sudo umount ${TEMP_MOUNT_POINT}
  sudo rmdir ${TEMP_MOUNT_POINT}
else
  echo "Shrinking '${BTRFS_FILE}' from ${OLD_SIZE} to ${NEW_SIZE} ..."
  echo "Warning: Shrinking below possible value may corrupt the filesystem!"
  read -p "Are you absolutely sure ? [y/N] " ANS
  if [[ ${ANS} == y ]]; then
    sudo mkdir -p ${TEMP_MOUNT_POINT}
    sudo mount ${BTRFS_FILE} ${TEMP_MOUNT_POINT} -o rw,noatime
    sudo btrfs filesystem resize ${NEW_SIZE} ${TEMP_MOUNT_POINT}
    df -h ${TEMP_MOUNT_POINT}
    sudo umount ${TEMP_MOUNT_POINT}
    sudo rmdir ${TEMP_MOUNT_POINT}
    truncate -s ${NEW_SIZE} ${BTRFS_FILE}
  fi
fi

