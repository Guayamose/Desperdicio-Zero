#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUN_ALL_SCRIPT="${ROOT_DIR}/scripts/run-all-maui.sh"

JAVA_HOME_DEFAULT="${HOME}/.local/jdk-17"
ANDROID_SDK_ROOT_DEFAULT="${HOME}/Android/Sdk"
AVD_NAME="${AVD_NAME:-DesperdicioZero_API34}"
EMU_ACCEL="${EMU_ACCEL:-on}"
WIPE_DATA="${WIPE_DATA:-0}"
EMULATOR_LOG="${EMULATOR_LOG:-/tmp/desperdicio-emulator-gui.log}"

export JAVA_HOME="${JAVA_HOME:-${JAVA_HOME_DEFAULT}}"
export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-${ANDROID_SDK_ROOT_DEFAULT}}"
export PATH="${HOME}/.dotnet:${JAVA_HOME}/bin:${ANDROID_SDK_ROOT}/platform-tools:${ANDROID_SDK_ROOT}/emulator:${ANDROID_SDK_ROOT}/cmdline-tools/11.0/bin:${PATH}"

EMU_LIBS="${HOME}/.local/emu-libs/usr/lib/x86_64-linux-gnu:${HOME}/.local/emu-libs/usr/lib/x86_64-linux-gnu/pulseaudio:${ANDROID_SDK_ROOT}/emulator/lib64:${ANDROID_SDK_ROOT}/emulator/lib64/qt/lib:${ANDROID_SDK_ROOT}/emulator/lib64/vulkan"

require_path() {
  local path="$1"
  local hint="$2"

  if [ ! -e "${path}" ]; then
    echo "${hint}" >&2
    exit 1
  fi
}

is_emulator_process_running() {
  pgrep -f "qemu-system-x86_64" >/dev/null 2>&1 \
    || pgrep -f "emulator .* -avd ${AVD_NAME}" >/dev/null 2>&1
}

is_emulator_visible_to_adb() {
  adb devices 2>/dev/null | awk '$1 ~ /^emulator-/ { print $1 }' | grep -q .
}

is_android_booted() {
  local sys_boot dev_boot bootanim provisioned

  sys_boot="$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')"
  dev_boot="$(adb shell getprop dev.bootcomplete 2>/dev/null | tr -d '\r')"
  bootanim="$(adb shell getprop init.svc.bootanim 2>/dev/null | tr -d '\r')"
  provisioned="$(adb shell settings get global device_provisioned 2>/dev/null | tr -d '\r')"

  if [ "${sys_boot}" = "1" ] || [ "${dev_boot}" = "1" ]; then
    return 0
  fi

  if [ "${bootanim}" = "stopped" ] || [ "${provisioned}" = "1" ]; then
    return 0
  fi

  return 1
}

is_android_framework_ready() {
  local package_path provisioned

  package_path="$(adb shell pm path android 2>/dev/null | tr -d '\r')"
  provisioned="$(adb shell settings get global device_provisioned 2>/dev/null | tr -d '\r')"

  if [ -n "${package_path}" ] && [ "${provisioned}" = "1" ]; then
    return 0
  fi

  return 1
}

wait_for_android_boot() {
  local boot_ok=0

  adb wait-for-device

  for _ in $(seq 1 300); do
    if is_android_booted; then
      boot_ok=1
      break
    fi
    sleep 2
  done

  if [ "${boot_ok}" -ne 1 ]; then
    echo "No se pudo confirmar el arranque completo de Android." >&2
    echo "Consulta el log del emulador en ${EMULATOR_LOG}" >&2
    exit 1
  fi
}

wait_for_android_framework() {
  for _ in $(seq 1 120); do
    if is_android_framework_ready; then
      return 0
    fi
    sleep 2
  done

  return 1
}

force_android_setup_complete() {
  adb shell settings put global device_provisioned 1 >/dev/null 2>&1 || true
  adb shell settings put secure user_setup_complete 1 >/dev/null 2>&1 || true
  adb shell settings put global setup_wizard_has_run 1 >/dev/null 2>&1 || true
  adb shell input keyevent KEYCODE_WAKEUP >/dev/null 2>&1 || true
  adb shell wm dismiss-keyguard >/dev/null 2>&1 || true
  adb shell input keyevent KEYCODE_HOME >/dev/null 2>&1 || true
}

kill_stale_processes() {
  echo "[prep 1/4] Cerrando procesos anteriores..."
  adb emu kill >/dev/null 2>&1 || true
  pkill -f "run-all-maui.sh" >/dev/null 2>&1 || true
  pkill -f "qemu-system-x86_64 .* -avd ${AVD_NAME}" >/dev/null 2>&1 || true
  pkill -f "emulator .* -avd ${AVD_NAME}" >/dev/null 2>&1 || true
  sleep 2
}

start_emulator() {
  local -a emulator_args
  local started=0

  emulator_args=(
    -avd "${AVD_NAME}"
    -no-metrics
    -no-snapshot-save
    -no-boot-anim
    -accel "${EMU_ACCEL}"
    -gpu swiftshader_indirect
  )

  if [ "${WIPE_DATA}" = "1" ]; then
    emulator_args=(
      -avd "${AVD_NAME}"
      -wipe-data
      -no-metrics
      -no-snapshot-save
      -no-boot-anim
      -accel "${EMU_ACCEL}"
      -gpu swiftshader_indirect
    )
  fi

  echo "[prep 2/4] Arrancando emulador..."
  nohup env LD_LIBRARY_PATH="${EMU_LIBS}:${LD_LIBRARY_PATH:-}" \
    emulator "${emulator_args[@]}" \
    >"${EMULATOR_LOG}" 2>&1 &

  for _ in $(seq 1 30); do
    if is_emulator_visible_to_adb || is_emulator_process_running; then
      started=1
      break
    fi
    sleep 2
  done

  if [ "${started}" -ne 1 ]; then
    echo "El emulador no ha quedado corriendo." >&2
    echo "Consulta el log: ${EMULATOR_LOG}" >&2
    tail -n 120 "${EMULATOR_LOG}" >&2 || true
    exit 1
  fi
}

echo "Preparando entorno MAUI para Android..."

require_path "${RUN_ALL_SCRIPT}" "No encuentro ${RUN_ALL_SCRIPT}"
require_path "${JAVA_HOME}" "No encuentro el JDK en ${JAVA_HOME}"
require_path "${ANDROID_SDK_ROOT}" "No encuentro el Android SDK en ${ANDROID_SDK_ROOT}"
require_path "${HOME}/.local/emu-libs/usr/lib/x86_64-linux-gnu/libpulse.so.0" "Faltan las librerias GUI del emulador. Ejecuta scripts/install-emulator-gui-libs.sh"

kill_stale_processes
start_emulator

echo "[prep 3/4] Esperando a que Android arranque..."
wait_for_android_boot

echo "[prep 4/4] Terminando configuracion inicial del emulador..."
force_android_setup_complete

if ! wait_for_android_framework; then
  echo "Android ha arrancado, pero el sistema todavia no esta listo para instalar apps." >&2
  echo "Intentando desbloquear la configuracion inicial una vez mas..." >&2
  force_android_setup_complete

  if ! wait_for_android_framework; then
    echo "El emulador sigue sin quedar listo." >&2
    echo "Prueba con WIPE_DATA=1 ./scripts/run-maui-guided.sh" >&2
    echo "Log del emulador: ${EMULATOR_LOG}" >&2
    exit 1
  fi
fi

echo "Emulador listo. Lanzando la app MAUI..."
exec "${RUN_ALL_SCRIPT}"
