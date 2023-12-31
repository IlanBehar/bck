#!/bin/bash

declare SECRET="42dac320ff3fee8ea3ece46024b20b38"
declare MULTI_JOBS="y"
declare ENABLE_TRACE="y"
declare MAC_ADDRESS="00:04:74:39:b6:7c"
declare COMPARATED_BRANCH="master"

# Log colors
declare -r GREEN='\033[0;32m'
declare -r YELLOW='\033[0;33m'
declare -r BLUE='\033[0;36m'
declare -r NC='\033[0m'

info()
{
  echo -e "${BLUE}""${1}""${NC}"
}

success()
{
  echo -e "${GREEN}""${1}""${NC}"
}

warning()
{
  echo -e "${YELLOW}""${1}""${NC}"
}


usage()
{
  echo "Usage : ./emb_gw.sh [generate_files|build|flash|connect|inte|prod|fpm|restore|forcebootload|change_wifi|log_netcom|test_heap_size|test_build_all]"
  echo "  -s : Specify secret"
  echo "  -m : Multy job (y or n)"
  echo "  -t : Enable trace (y or no)"
  echo "  -v : Firmware version"
  echo "  -a : MAC address"
  echo "  -b : branch to compare for test. By default master is used"
  exit
}

declare -r ACTION=$1
OPTIND=2

while getopts "s:m:t:v:h:a:b:" option; do
  case "${option}" in
  s) SECRET=${OPTARG}
     ;;
  m) MULTI_JOBS=${OPTARG}
    [ "${MULTI_JOBS}" == "y" ] || [ "${MULTI_JOBS}" == "n" ] || usage
     ;;
  t) ENABLE_TRACE=${OPTARG}
    [ "${ENABLE_TRACE}" == "y" ] || [ "${ENABLE_TRACE}" == "n" ] || usage
     ;;
  v) FIRMWARE_VERSION=${OPTARG}
  ;;
  a) MAC_ADDRESS=${OPTARG}
  ;;
  b) COMPARATED_BRANCH=${OPTARG}
  ;;
  h) usage
     ;;
  *) warning "Unknown option"
     usage
     exit
     ;;
  esac
done

shift $((OPTIND-1))

if [ -z ${ACTION+x} ]; then usage; fi

if  [ "${ACTION}" != "generate_files" ] &&[ "${ACTION}" != "build" ] && \
    [ "${ACTION}" != "flash" ] && [ "${ACTION}" != "connect" ] && \
    [ "${ACTION}" != "inte" ] && [ "${ACTION}" != "prod" ] && [ "${ACTION}" != "fpm" ] && \
    [ "${ACTION}" != "restore" ] && [ "${ACTION}" != "forcebootload" ] && \
    [ "${ACTION}" != "change_wifi" ] && [ "${ACTION}" != "log_netcom" ] && \
    [ "${ACTION}" != "test_heap_size" ] && [ "${ACTION}" != "test_build_all" ] \
    ;then usage; fi

if [ ${ACTION} == "build" ] || [ ${ACTION} == "flash" ];
then
    if [ -z ${FIRMWARE_VERSION+x} ];
    then
      warning "-v not specify defaulting version to 4242"
      FIRMWARE_VERSION=4242;
      fi
fi

declare COMMAND=""
case "${ACTION}" in
generate_files)
  COMMAND="make prebuild_files"
  ;;
build)
  COMMAND="make nlg-stm32-v2 MULTI_JOBS=${MULTI_JOBS} ENABLE_TRACE=${ENABLE_TRACE} FIRMWARE_VERSION=${FIRMWARE_VERSION}"
  ;;
flash)
  COMMAND="make nlgV2.reflash SECRET=${SECRET} MULTI_JOBS=${MULTI_JOBS} ENABLE_TRACE=${ENABLE_TRACE} FIRMWARE_VERSION=${FIRMWARE_VERSION}"
  ;;
connect)
  COMMAND="minicom -D /dev/ttyUSB0 -c on -R UTF-8"
  ;;
inte)
  COMMAND="./modules/python-emb-tools/python/bin/netcom/netcom_dblib.py -s DBLIB_IE_NETCOMV2_SERVER:0 \"netcomv2.inte.netatmo.net\" iap_usb"
  ;;
prod)
  COMMAND="./modules/python-emb-tools/python/bin/netcom/netcom_dblib.py -s DBLIB_IE_NETCOMV2_SERVER:0 \"nv2-nlg.netatmo.net\" iap_usb"
  ;;
fpm)
  COMMAND="netcom_reboot.py -m plug iap_usb"
  ;;
restore)
  COMMAND="./scripts/gateway_first_flash/gateway_first_flash.sh -s 2 -m ${MAC_ADDRESS} -r 404 ${SECRET} && echo \"Remember to switch to inte if needed\""
  ;;
forcebootload)
  COMMAND="make forcebootload"
  ;;
change_wifi)
  COMMAND="netcom_configure_wifi.py iap_usb"
  ;;
log_netcom)
  COMMAND="netcom_rx_tx_decoder.py -l 959 -t 2 -i ${MAC_ADDRESS}"
  ;;
test_heap_size)
COMMAND="make clean && git rebase \$(git merge-base HEAD ${COMPARATED_BRANCH}) -x 'git submodule update && make FIRMWARE_VERSION=4242 MULTI_JOBS=y nlgV2'"
  ;;
test_build_all)
COMMAND="make clean &&
                   git rebase \$(git merge-base HEAD ${COMPARATED_BRANCH}) -x 'git submodule update && make nlg-linux BUILD_EXECUTABLE=y BUILD_SHARED_LIBRARY_TEST=y BUILD_VARIANTS=bncx' &&
                   git rebase \$(git merge-base HEAD ${COMPARATED_BRANCH}) -x 'git submodule update && make nlg-stm32-v2 FIRMWARE_VERSION=4242 MULTI_JOBS=y ENABLE_TRACE=y' &&
                   git rebase \$(git merge-base HEAD ${COMPARATED_BRANCH}) -x 'git submodule update && make  -C apps test-nlg-abi-converter-nvm'"
  ;;
esac

cd ~/work/embedded/magellan
info "${COMMAND}"
${COMMAND}
