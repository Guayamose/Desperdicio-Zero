#!/usr/bin/env bash
set -euo pipefail

AVD_NAME="${AVD_NAME:-DesperdicioZero_API34}"
APP_PACKAGE="com.socialkitchen.desperdiciozero.user"
ANDROID_SDK_ROOT_DEFAULT="${HOME}/Android/Sdk"
AVD_DIR="${HOME}/.android/avd/${AVD_NAME}.avd"

export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-${ANDROID_SDK_ROOT_DEFAULT}}"
export PATH="${ANDROID_SDK_ROOT}/platform-tools:${PATH}"

adb_has_device() {
  adb devices 2>/dev/null | awk '$1 ~ /^emulator-/ && $2 == "device" { found=1 } END { exit found ? 0 : 1 }'
}

stop_emulator_via_adb() {
  if adb_has_device; then
    adb shell am force-stop "${APP_PACKAGE}" >/dev/null 2>&1 || true
    adb emu kill >/dev/null 2>&1 || true
    return 0
  fi

  return 1
}

echo "[1/2] Cerrando app MAUI..."
if adb_has_device; then
  adb shell am force-stop "${APP_PACKAGE}" >/dev/null 2>&1 || true
fi

echo "[2/2] Cerrando emulador..."
if stop_emulator_via_adb; then
  echo "Emulador cerrado por adb."
elif pgrep -f "qemu-system-x86_64 .* -avd ${AVD_NAME}" >/dev/null 2>&1 \
  || pgrep -f "qemu-system-x86_64-headless .* -avd ${AVD_NAME}" >/dev/null 2>&1 \
  || pgrep -f "emulator .* -avd ${AVD_NAME}" >/dev/null 2>&1; then
  pkill -f "qemu-system-x86_64-headless .* -avd ${AVD_NAME}" >/dev/null 2>&1 || true
  pkill -f "qemu-system-x86_64 .* -avd ${AVD_NAME}" >/dev/null 2>&1 || true
  pkill -f "emulator .* -avd ${AVD_NAME}" >/dev/null 2>&1 || true
  echo "Emulador cerrado por proceso."
else
  echo "No habia emulador de ${AVD_NAME} en ejecucion."
fi

rm -f "${AVD_DIR}/hardware-qemu.ini.lock" "${AVD_DIR}/multiinstance.lock"

echo "Listo."
