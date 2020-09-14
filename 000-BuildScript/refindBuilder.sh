#!/usr/bin/env bash

# Provide custom colors
msg_info() {
    echo -e "\033[0;33m$1\033[0m"
}
msg_status() {
    echo -e "\033[0;32m$1\033[0m"
}
msg_error() {
    echo -e "\033[0;31m$1\033[0m"
}

## ERROR HANDLER ##
runErr() { # $1: message
    # Declare Local Variables
    local errMessage

    errMessage="${1:-Runtime Error ... Exiting}"
    echo ''
    msg_error "${errMessage}"
    echo ''
    echo ''
    exit 1
}
trap runErr ERR

# Set things up and move into build folder
clear
msg_info '## RefindBuilder - Setting Up ##'
msg_info '--------------------------------'
sleep 1
EDIT_BRANCH="${1:-GOPFix}"
BASE_DIR="${HOME}/Documents/RefindPlus"
WORK_DIR="${BASE_DIR}/Working"
EDK2_DIR="${BASE_DIR}/edk2"
if [ ! -d "${EDK2_DIR}" ] ; then
    msg_error "ERROR: Could not locate ${EDK2_DIR}"
    echo ''
    exit 1
fi
XCODE_DIR_REL="${EDK2_DIR}/Build/Refind/RELEASE_XCODE5"
XCODE_DIR_DBG="${EDK2_DIR}/Build/Refind/DEBUG_XCODE5"
XCODE_DIR_TMP="${EDK2_DIR}/Build-DBG/Refind/RELEASE_XCODE5"
BINARY_DIR="${XCODE_DIR_REL}/X64"
OUTPUT_DIR="${EDK2_DIR}/000-BOOTx64-Files"
GLOBAL_FILE="${EDK2_DIR}/RefindPkg/refind/globalExtra.h"
GLOBAL_FILE_TMP_REL="${EDK2_DIR}/RefindPkg/refind/globalExtra-REL.txt"
GLOBAL_FILE_TMP_DBG="${EDK2_DIR}/RefindPkg/refind/globalExtra-DBG.txt"

pushd ${WORK_DIR} > /dev/null || exit 1
git checkout ${EDIT_BRANCH}
rm -fr "${EDK2_DIR}/RefindPkg"
cp -fa "${WORK_DIR}" "${EDK2_DIR}/RefindPkg"
rm -fr "${EDK2_DIR}/RefindPkg/.gitignore"
rm -fr "${EDK2_DIR}/RefindPkg/.git"
popd > /dev/null || exit 1


# Basic clean up
clear
msg_info '## RefindPlusBuilder - Initial Clean Up ##'
msg_info '------------------------------------------'
sleep 1
if [ -d "${EDK2_DIR}/Build-OLD" ] ; then
    rm -fr "${EDK2_DIR}/Build-OLD"
fi
if [ -d "${EDK2_DIR}/Build" ] ; then
    mv "${EDK2_DIR}/Build" "${EDK2_DIR}/Build-OLD"
fi
if [ -d "${OUTPUT_DIR}" ] ; then
    rm -fr "${OUTPUT_DIR}"
fi
mkdir -p "${OUTPUT_DIR}"


# Build release version
clear
msg_info '## RefindPlusBuilder - Building REL Version ##'
msg_info '----------------------------------------------'
sleep 1
pushd ${EDK2_DIR} > /dev/null || exit 1
if [ -d "${EDK2_DIR}/Build-TMP" ] ; then
    rm -fr "${EDK2_DIR}/Build-TMP"
fi
if [ -f "${GLOBAL_FILE}" ] ; then
    rm -fr "${GLOBAL_FILE}"
fi
cp "${GLOBAL_FILE_TMP_REL}" "${GLOBAL_FILE}"
source edksetup.sh BaseTools
build
if [ -d "${EDK2_DIR}/Build" ] ; then
    cp "${BINARY_DIR}/refind.efi" "${OUTPUT_DIR}/BOOTx64-REL.efi"
    mv "${EDK2_DIR}/Build" "${EDK2_DIR}/Build-TMP"
fi
popd > /dev/null || exit 1
echo ''
msg_info 'Completed REL Build ...Preparing DBG Build'
echo ''
sleep 3


# Build debug version
clear
msg_info '## RefindPlusBuilder - Building DBG Version ##'
msg_info '----------------------------------------------'
sleep 1
pushd ${EDK2_DIR} > /dev/null || exit 1
if [ -d "${EDK2_DIR}/Build-DBG" ] ; then
    rm -fr "${EDK2_DIR}/Build-DBG"
fi
if [ -f "${GLOBAL_FILE}" ] ; then
    rm -fr "${GLOBAL_FILE}"
fi
cp "${GLOBAL_FILE_TMP_DBG}" "${GLOBAL_FILE}"
source edksetup.sh BaseTools
build
if [ -d "${EDK2_DIR}/Build" ] ; then
    cp "${BINARY_DIR}/refind.efi" "${OUTPUT_DIR}/BOOTx64-DBG.efi"
    mv "${EDK2_DIR}/Build" "${EDK2_DIR}/Build-DBG"
    mv "${EDK2_DIR}/Build-TMP" "${EDK2_DIR}/Build"
    mv "${XCODE_DIR_TMP}" "${XCODE_DIR_DBG}"
fi
if [ -d "${EDK2_DIR}/Build-DBG" ] ; then
    rm -fr "${EDK2_DIR}/Build-DBG"
fi
popd > /dev/null || exit 1
echo ''
msg_info 'Completed DBG Build'
echo ''


# Tidy up
if [ -f "${GLOBAL_FILE}" ] ; then
    rm -fr "${GLOBAL_FILE}"
fi
cp "${GLOBAL_FILE_TMP_REL}" "${GLOBAL_FILE}"
echo ''
msg_status "RefindPlus EFI Files (BOOTx64): '${OUTPUT_DIR}'"
msg_status "RefindPlus EFI Files (Others - DBG): '${XCODE_DIR_DBG}/X64'"
msg_status "RefindPlus EFI Files (Others - REL): '${XCODE_DIR_REL}/X64'"
echo ''
echo ''
