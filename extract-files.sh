#!/bin/bash
#
# Copyright (C) 2016 The CyanogenMod Project
# Copyright (C) 2017-2020 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

set -e

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

ANDROID_ROOT="${MY_DIR}/../../.."

HELPER="${ANDROID_ROOT}/tools/extract-utils/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
    echo "Unable to find helper script at ${HELPER}"
    exit 1
fi
source "${HELPER}"

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true

ONLY_COMMON=
ONLY_TARGET=
KANG=
SECTION=

while [ "${#}" -gt 0 ]; do
    case "${1}" in
        --only-common )
                ONLY_COMMON=true
                ;;
        --only-target )
                ONLY_TARGET=true
                ;;
        -n | --no-cleanup )
                CLEAN_VENDOR=false
                ;;
        -k | --kang )
                KANG="--kang"
                ;;
        -s | --section )
                SECTION="${2}"; shift
                CLEAN_VENDOR=false
                ;;
        * )
                SRC="${1}"
                ;;
    esac
    shift
done

function blob_fixup() {
    case "${1}" in
        lib64/libsink.so)
            "${PATCHELF}" --add-needed "libshim_vtservice.so" "${2}"
            ;;
        vendor/bin/hw/vendor.xiaomi.hardware.vibratorfeature.service)
            sed -i "s/\x00\x2F\x76\x69\x62\x72\x61\x74\x6F\x72\x66\x65\x61\x74\x75\x72\x65\x00/\x00\x2F\x64\x65\x66\x61\x75\x6C\x74\x00\x00\x00\x00\x00\x00\x00\x00\x00/g" "${2}"
            "${PATCHELF}" --replace-needed libutils.so libutils-v32.so "${2}"
            ;;
        vendor/etc/vintf/manifest/vendor.xiaomi.hardware.vibratorfeature.service.xml)
            sed -i "s/vibratorfeature/default/g" "${2}"
            ;;
        vendor/bin/hw/vendor.mediatek.hardware.pq@2.2-service | vendor/bin/hw/mt6895/camerahalserver | vendor/bin/hw/android.hardware.thermal@2.0-service.mtk)
            "${PATCHELF}" --replace-needed libutils.so libutils-v32.so "${2}"
            ;;
        vendor/bin/hw/android.hardware.security.keymint@1.0-service.beanpod)
            "${PATCHELF}" --add-needed android.hardware.security.rkp-V1-ndk.so "${2}"
            ;;
    esac
}

if [ -z "${SRC}" ]; then
    SRC="adb"
fi

if [ -z "${ONLY_TARGET}" ]; then
    # Initialize the helper for common device
    setup_vendor "${DEVICE_COMMON}" "${VENDOR}" "${ANDROID_ROOT}" true "${CLEAN_VENDOR}"

    extract "${MY_DIR}/proprietary-files.txt" "${SRC}" "${KANG}" --section "${SECTION}"
fi

if [ -z "${ONLY_COMMON}" ] && [ -s "${MY_DIR}/../${DEVICE}/proprietary-files.txt" ]; then
    # Reinitialize the helper for device
    source "${MY_DIR}/../${DEVICE}/extract-files.sh"
    setup_vendor "${DEVICE}" "${VENDOR}" "${ANDROID_ROOT}" false "${CLEAN_VENDOR}"

    extract "${MY_DIR}/../${DEVICE}/proprietary-files.txt" "${SRC}" "${KANG}" --section "${SECTION}"
fi

"${MY_DIR}/setup-makefiles.sh"