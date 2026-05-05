#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MAUI_DIR="${ROOT_DIR}/frontend-maui-user/DesperdicioZero.User.Maui"

JAVA_HOME_DEFAULT="${HOME}/.local/jdk-17"
ANDROID_SDK_ROOT_DEFAULT="${HOME}/Android/Sdk"
AVD_NAME="${AVD_NAME:-DesperdicioZero_API34}"
EMU_ACCEL="${EMU_ACCEL:-on}"
EMU_MODE="${EMU_MODE:-auto}"
APP_PACKAGE="com.socialkitchen.desperdiciozero.user"
APP_APK="${MAUI_DIR}/bin/Debug/net8.0-android/${APP_PACKAGE}-Signed.apk"
AVD_DIR="${HOME}/.android/avd/${AVD_NAME}.avd"
EMULATOR_RUNTIME_MODE=""

is_valid_jdk_home() {
  local jdk_home="${1:-}"

  [ -n "${jdk_home}" ] \
    && [ -x "${jdk_home}/bin/java" ] \
    && [ -x "${jdk_home}/bin/javac" ] \
    && [ -x "${jdk_home}/bin/jar" ]
}

resolve_java_home() {
  if is_valid_jdk_home "${JAVA_HOME:-}"; then
    printf '%s\n' "${JAVA_HOME}"
    return 0
  fi

  if [ -n "${JAVA_HOME:-}" ]; then
    echo "JAVA_HOME='${JAVA_HOME}' no apunta a un JDK valido. Usando ${JAVA_HOME_DEFAULT}." >&2
  fi

  if is_valid_jdk_home "${JAVA_HOME_DEFAULT}"; then
    printf '%s\n' "${JAVA_HOME_DEFAULT}"
    return 0
  fi

  echo "No se encontro un JDK valido. Revisa ${JAVA_HOME_DEFAULT}." >&2
  exit 1
}

resolve_dotnet_bin() {
  if [ -x "${HOME}/.dotnet/dotnet" ]; then
    printf '%s\n' "${HOME}/.dotnet/dotnet"
    return 0
  fi

  if command -v dotnet >/dev/null 2>&1; then
    command -v dotnet
    return 0
  fi

  echo "No se encontro dotnet en ~/.dotnet ni en PATH." >&2
  exit 1
}

export JAVA_HOME="$(resolve_java_home)"
export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-${ANDROID_SDK_ROOT_DEFAULT}}"
DOTNET_BIN="$(resolve_dotnet_bin)"
export PATH="${HOME}/.dotnet:${JAVA_HOME}/bin:${ANDROID_SDK_ROOT}/platform-tools:${ANDROID_SDK_ROOT}/emulator:${ANDROID_SDK_ROOT}/cmdline-tools/11.0/bin:${PATH}"

EMU_LIBS="${HOME}/.local/emu-libs/usr/lib/x86_64-linux-gnu:${HOME}/.local/emu-libs/usr/lib/x86_64-linux-gnu/pulseaudio:${ANDROID_SDK_ROOT}/emulator/lib64:${ANDROID_SDK_ROOT}/emulator/lib64/qt/lib:${ANDROID_SDK_ROOT}/emulator/lib64/vulkan"

wait_backend() {
  for _ in $(seq 1 60); do
    if curl -fsS http://127.0.0.1:3000/up >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done
  return 1
}

is_emulator_process_running() {
  pgrep -f "qemu-system-x86_64-headless .* -avd ${AVD_NAME}" >/dev/null 2>&1 \
    || pgrep -f "qemu-system-x86_64 .* -avd ${AVD_NAME}" >/dev/null 2>&1 \
    || pgrep -f "emulator .* -avd ${AVD_NAME}" >/dev/null 2>&1
}

adb_has_device() {
  adb devices 2>/dev/null | awk '$1 ~ /^emulator-/ && $2 == "device" { found=1 } END { exit found ? 0 : 1 }'
}

ensure_adb_server() {
  adb start-server >/dev/null 2>&1 || true
}

reset_adb_server() {
  adb kill-server >/dev/null 2>&1 || true
  ensure_adb_server
}

kill_avd_processes() {
  pkill -f "qemu-system-x86_64-headless .* -avd ${AVD_NAME}" >/dev/null 2>&1 || true
  pkill -f "qemu-system-x86_64 .* -avd ${AVD_NAME}" >/dev/null 2>&1 || true
  pkill -f "emulator .* -avd ${AVD_NAME}" >/dev/null 2>&1 || true
}

clear_stale_avd_locks() {
  if is_emulator_process_running; then
    return 1
  fi

  rm -f "${AVD_DIR}/hardware-qemu.ini.lock" "${AVD_DIR}/multiinstance.lock"
}

avd_images_in_use() {
  fuser "${AVD_DIR}/cache.img.qcow2" "${AVD_DIR}/userdata-qemu.img.qcow2" >/dev/null 2>&1
}

wait_for_avd_release() {
  local timeout_seconds="${1:-30}"
  local started_at now

  started_at="$(date +%s)"

  while true; do
    if ! is_emulator_process_running \
      && [ ! -f "${AVD_DIR}/hardware-qemu.ini.lock" ] \
      && [ ! -f "${AVD_DIR}/multiinstance.lock" ] \
      && ! avd_images_in_use; then
      return 0
    fi

    now="$(date +%s)"
    if [ $((now - started_at)) -ge "${timeout_seconds}" ]; then
      break
    fi

    sleep 1
  done

  kill_avd_processes
  sleep 2
  clear_stale_avd_locks || true

  ! is_emulator_process_running
}

start_gui_emulator() {
  EMULATOR_RUNTIME_MODE="gui"
  env LD_LIBRARY_PATH="${EMU_LIBS}:${LD_LIBRARY_PATH:-}" \
    setsid -f emulator -avd "${AVD_NAME}" -no-metrics -no-snapshot-save -no-boot-anim -accel "${EMU_ACCEL}" -gpu swiftshader_indirect \
    </dev/null >/tmp/desperdicio-emulator-gui.log 2>&1
}

start_headless_emulator() {
  EMULATOR_RUNTIME_MODE="headless"
  setsid -f emulator -avd "${AVD_NAME}" -no-window -no-metrics -no-snapshot-save -no-boot-anim -no-audio -accel "${EMU_ACCEL}" -gpu swiftshader_indirect \
    </dev/null >/tmp/desperdicio-emulator.log 2>&1
}

wait_for_adb_device() {
  local timeout_seconds="${1:-90}"
  local startup_grace_seconds=10
  local started_at now elapsed

  started_at="$(date +%s)"

  while true; do
    if adb_has_device; then
      return 0
    fi

    now="$(date +%s)"
    elapsed=$((now - started_at))

    if [ "${elapsed}" -ge "${startup_grace_seconds}" ] && ! is_emulator_process_running; then
      return 1
    fi

    if [ "${elapsed}" -ge "${timeout_seconds}" ]; then
      return 1
    fi

    sleep 2
  done
}

recover_with_headless() {
  if [ "${EMU_MODE}" != "auto" ] || [ "${EMULATOR_RUNTIME_MODE}" != "gui" ]; then
    return 1
  fi

  echo "El emulador con ventana se ha desconectado durante el arranque. Reintentando en modo headless..." >&2
  kill_avd_processes
  wait_for_avd_release 30 || true
  reset_adb_server
  start_headless_emulator
  wait_for_adb_device 120
}

launch_emulator() {
  ensure_adb_server

  if adb_has_device; then
    return 0
  fi

  if is_emulator_process_running; then
    echo "Se ha detectado un emulador en ejecucion. Esperando conexion por adb..."
    if wait_for_adb_device 90; then
      return 0
    fi

    echo "El emulador existente no se ha conectado. Reiniciando intento..." >&2
    kill_avd_processes
    wait_for_avd_release 30 || true
  fi

  case "${EMU_MODE}" in
    headless)
      echo "Arrancando emulador en modo headless..."
      reset_adb_server
      start_headless_emulator
      if wait_for_adb_device 120; then
        return 0
      fi
      ;;
    gui)
      echo "Arrancando emulador con ventana..."
      start_gui_emulator
      if wait_for_adb_device 120; then
        return 0
      fi
      ;;
    auto)
      echo "Intentando arrancar emulador con ventana..."
      start_gui_emulator
      if wait_for_adb_device 60; then
        return 0
      fi

      echo "El emulador con ventana no ha quedado listo. Probando modo headless..." >&2
      kill_avd_processes
      wait_for_avd_release 30 || true

      reset_adb_server
      start_headless_emulator
      if wait_for_adb_device 120; then
        return 0
      fi
      ;;
    *)
      echo "EMU_MODE debe ser auto, gui o headless. Valor recibido: ${EMU_MODE}" >&2
      exit 1
      ;;
  esac

  echo "No se pudo conectar ningun emulador Android por adb." >&2
  exit 1
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

is_package_installed() {
  adb shell pm path "${APP_PACKAGE}" >/dev/null 2>&1
}

wait_for_android_framework() {
  for _ in $(seq 1 180); do
    if is_android_framework_ready; then
      return 0
    fi

    if ! adb_has_device || ! is_emulator_process_running; then
      return 1
    fi

    sleep 2
  done
  return 1
}

wait_for_android_boot() {
  for _ in $(seq 1 300); do
    if is_android_booted; then
      return 0
    fi

    if ! adb_has_device || ! is_emulator_process_running; then
      return 1
    fi

    sleep 2
  done

  return 1
}

install_app() {
  timeout 180s adb install --no-incremental -r "${APP_APK}"
}

echo "[1/5] Verificando backend Rails..."
if ! wait_backend; then
  echo "Arrancando backend Rails en background..."
  (
    cd "${ROOT_DIR}"
    nohup bin/rails server -b 0.0.0.0 -p 3000 >/tmp/desperdicio-rails.log 2>&1 &
  )
  wait_backend
fi

echo "[2/5] Arrancando emulador..."
launch_emulator

echo "[3/5] Esperando boot de Android..."
if ! wait_for_android_boot; then
  if ! recover_with_headless || ! wait_for_android_boot; then
    echo "No se pudo confirmar boot completo en 10 minutos." >&2
    echo "Prueba reiniciar el emulador y volver a ejecutar este script." >&2
    exit 1
  fi
fi

echo "[3b/5] Esperando servicios del sistema Android..."
if ! wait_for_android_framework; then
  if ! recover_with_headless || ! wait_for_android_boot || ! wait_for_android_framework; then
    echo "Android ha arrancado, pero Settings/PackageManager todavia no estan listos." >&2
    echo "Abre el emulador, espera a ver la pantalla principal y vuelve a ejecutar el script." >&2
    exit 1
  fi
fi

adb shell input keyevent KEYCODE_WAKEUP >/dev/null 2>&1 || true
adb shell wm dismiss-keyguard >/dev/null 2>&1 || true

echo "[4/5] Compilando app MAUI..."
cd "${MAUI_DIR}"
"${DOTNET_BIN}" build \
  -p:TargetFramework=net8.0-android \
  -p:JavaSdkDirectory="${JAVA_HOME}" \
  -p:AndroidSdkDirectory="${ANDROID_SDK_ROOT}" \
  -p:EmbedAssembliesIntoApk=true \
  -p:AndroidFastDeploymentType=None \
  -v minimal

echo "[5/5] Instalando y abriendo app..."
if ! install_app; then
  echo "Primer intento de instalacion fallido. Reintentando tras refrescar el estado del emulador..."
  adb wait-for-device

  if ! wait_for_android_framework; then
    echo "El emulador ha perdido el estado listo para instalar apps." >&2
    echo "Cierra el emulador, vuelve a abrirlo y espera a la pantalla principal." >&2
    exit 1
  fi

  if ! install_app; then
    if is_package_installed; then
      echo "Instalacion completada, pero adb no devolvio estado. Continuando..."
    else
      echo "Fallo o timeout al instalar APK." >&2
      exit 1
    fi
  fi
fi

RESOLVED_ACTIVITY="$(adb shell cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.LAUNCHER "${APP_PACKAGE}" 2>/dev/null | tail -n 1 | tr -d '\r')"
if [ -n "${RESOLVED_ACTIVITY}" ] && [ "${RESOLVED_ACTIVITY}" != "No activity found" ]; then
  adb shell am start -n "${RESOLVED_ACTIVITY}"
else
  adb shell monkey -p "${APP_PACKAGE}" 1
fi

echo
echo "Listo."
echo "Backend: http://127.0.0.1:3000"
echo "La app publica usa por defecto: http://10.0.2.2:3000"
