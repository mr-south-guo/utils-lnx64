#!/bin/bash

SCRIPTFULLPATH=$( readlink -f "$BASH_SOURCE" )
THIS=${SCRIPTFULLPATH##*/}

log_msg() {
  if [ ${OPT_QUIET} ]; then return; fi
  echo -e "$@"
}

HELP_MSG="\
Sync two files of the same size by updating only different blocks.

For each block (1MiB) of the two files, they are read, compared and updated (if different).
This process is much more efficient than 'rsync --inplace --no-whole-file ...'.
Particularly useful for syncing two large files of the same size with only small changes,
such as virtual harddisk. Great for SSD harddisk's health.

Usage:
${THIS} -h 
${THIS} [-q] -s <source> -d <destination>

Options:
    -h               This help message
    -q               Quiet, i.e. no info, warning and progress except error
    -s <source>      Source file/device
    -d <destination> Destination file/device
\
"

while getopts ':hqs:d:' option; do
  case "$option" in
    h) echo "${HELP_MSG}"
       exit
       ;;
    s) dev1=$OPTARG
       ;;
    d) dev2=$OPTARG
       ;;
    q) OPT_QUIET=1
       ;;
    :) echo "[ERR] Missing argument for -${OPTARG}"
       echo "${HELP_MSG}"
       exit 1
       ;;
   \?) echo "[ERR] Illegal option: -${OPTARG}"
       echo "${HELP_MSG}"
       exit 1
       ;;
  esac
done
shift $((OPTIND - 1))

if [ -z "${dev1}" ] || [ -z "${dev2}" ]; then
    echo "[ERR] Not enough options"
    echo "${HELP_MSG}"
    exit
fi

# Check if the two dev exists
if [ ! -e ${dev1} ]; then
  echo "${dev1} does not exist!"
  exit 1
fi
if [ ! -e ${dev2} ]; then
  echo "${dev2} does not exist!"
  exit 1
fi

# Get the size of dev1
if [[ $dev1 == /dev/* ]]
then
  SIZE=`blockdev --getsize64 ${dev1}`
else
  SIZE=`stat -c %s ${dev1}`
fi

# Get the size of dev2
if [[ $dev2 == /dev/* ]]
then
  SIZE2=`blockdev --getsize64 ${dev2}`
else
  SIZE2=`stat -c %s ${dev2}`
fi

# Check if the two sizes are identical
if [ "${SIZE}" -ne "${SIZE2}" ]; then
  echo "*** Size mismatch!!! ***"
  echo "${dev1}: ${SIZE} bytes"
  echo "${dev2}: ${SIZE2} bytes"
  read -p "Are you sure? [y/N]" answer
  if [ "${answer}" != "y" ]; then
    echo "Aborted by user."
    exit 1
  fi
fi

PV1="tee"
PV2="tee"
if [ ! ${OPT_QUIET} ]; then
  # Find pv (pipe progress viewer)
  PV=$(which pv)
  if [ -z ${PV} ]; then
    PV="./pv"
  fi
  if [ -f ${PV} ]; then
    # Progress bar for overall sync
    PV1="${PV} -p -t -e -a -s ${SIZE} -c -N Sync"
    # Stats for Diff data copied
    PV2="${PV} -b -c -N Diff"
  else
    log_msg "pv not found! if you want to see progress, install it."
  fi
fi

# Start syncing!
log_msg "Syncing begins ..."
log_msg "from : ${dev1}"
log_msg "  to : ${dev2}"
log_msg "size : $((SIZE/1024/1024))MiB"

# Ref: https://lists.samba.org/archive/rsync/2010-June/025164.html
perl -ne 'BEGIN{$/=\1024}; print $_' ${dev2} | ${PV1} | \
  perl -'MDigest::MD5 md5' -ne 'BEGIN{$/=\1024}; print md5($_)' | \
  perl -'MDigest::MD5 md5' -ne 'BEGIN{$/=\1024}; $b=md5($_); read STDIN,$a,16; if ($a eq $b) {print "s"} else {print "c" . $_}' ${dev1} | ${PV2} | \
  perl -ne 'BEGIN{$/=\1} if ($_ eq"s") {$s++} else {if ($s) {seek STDOUT,$s*1024,1; $s=0}; read ARGV,$buf,1024; print $buf}' 1<> ${dev2}

# After using 'pv -c', the terminal may not show user input. The following command fix it.
stty sane
log_msg "Note: The actual diff should be the [Diff - $((SIZE/1024/1024))KiB]."

# Sync the timestamp
touch --reference=${dev1} ${dev2}
