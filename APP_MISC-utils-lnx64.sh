#!/bin/echo *** This script should only be sourced, e.g.: . 

###
# Activate/Deactivate script for RDE-Env App
# version: 1.0
# - To enable corresponding app: copy this script to <root>/env/<env-name>/.enable/
# - The following variables are provided by the caller script:
#    - ${RDE_APP_MOUNT_ROOT} : the common root all this env's apps may be mount to
#    - ${RDE_ENV_LIB} : the <root>/lib/ directory where all apps' files located
###

RDE_APP_NAME=misc
RDE_APP_SUFFIX=utils-lnx64
RDE_APP_SRC_DIR=${RDE_ENV_LIB}/${RDE_APP_NAME}/${RDE_APP_SUFFIX}
RDE_APP_MOUNT_POINT=${RDE_APP_SRC_DIR}

case "${RDE_ENV_ACTION}" in
  activate)
    Sub_ProcessDesktop
    Sub_AppendToSetEnvFile "
## Misc: utils-lnx64
export PATH=${RDE_APP_MOUNT_POINT}/bin:\${PATH}
"
    ;;
  deactivate)
    echo "Nothing to do." > /dev/null
    ;;
  *)
    log_msg "[WRN] I don't understand: RDE_ENV_ACTION=${RDE_ENV_ACTION}"
    ;;
esac
