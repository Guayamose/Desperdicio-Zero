#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MAUI_DIR="${ROOT_DIR}/frontend-maui-user/DesperdicioZero.User.Maui"

JAVA_HOME_DEFAULT="${HOME}/.local/jdk-17"
ANDROID_SDK_ROOT_DEFAULT="${HOME}/Android/Sdk"
DOTNET_BIN="${HOME}/.dotnet/dotnet"
AVD_NAME="${AVD_NAME:-DesperdicioZero_API34}"
APP_PACKAGE="com.socialkitchen.desperdiciozero.user"
APP_APK="${MAUI_DIR}/bin/Debug/net8.0-android/${APP_PACKAGE}-Signed.apk"

export JAVA_HOME="${JAVA_HOME:-${JAVA_HOME_DEFAULT}}"
export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-${ANDROID_SDK_ROOT_DEFAULT}}"
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

is_package_installed() {
  adb shell pm path "${APP_PACKAGE}" >/dev/null 2>&1
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
if ! adb devices | grep -q '^emulator-'; then
  # Try GUI mode with local libs.
  nohup env LD_LIBRARY_PATH="${EMU_LIBS}:${LD_LIBRARY_PATH:-}" \
    emulator -avd "${AVD_NAME}" -no-metrics -no-snapshot-save -no-boot-anim -accel off -gpu swiftshader_indirect \
    >/tmp/desperdicio-emulator-gui.log 2>&1 &

  sleep 10

  # Fallback to headless mode if GUI did not start.
  if ! pgrep -f "qemu-system-x86_64 .* -avd ${AVD_NAME}" >/dev/null; then
    nohup emulator -avd "${AVD_NAME}" -no-window -no-metrics -no-snapshot-save -no-boot-anim -no-audio -accel off -gpu swiftshader_indirect \
      >/tmp/desperdicio-emulator.log 2>&1 &
  fi
fi

echo "[3/5] Esperando boot de Android..."
adb wait-for-device
BOOT_OK=0
for _ in $(seq 1 300); do
  if is_android_booted; then
    BOOT_OK=1
    break
  fi
  sleep 2
done
if [ "${BOOT_OK}" -ne 1 ]; then
  echo "No se pudo confirmar boot completo en 10 minutos." >&2
  echo "Prueba reiniciar el emulador y volver a ejecutar este script." >&2
  exit 1
fi

echo "[4/5] Compilando app MAUI..."
cd "${MAUI_DIR}"
"${DOTNET_BIN}" build -p:TargetFramework=net8.0-android -p:JavaSdkDirectory="${JAVA_HOME}" -p:AndroidSdkDirectory="${ANDROID_SDK_ROOT}" -v minimal

echo "[5/5] Instalando y abriendo app..."
if ! timeout 180s adb install --no-incremental -r "${APP_APK}"; then
  if is_package_installed; then
    echo "Instalacion completada, pero adb no devolvio estado. Continuando..."
  else
    echo "Fallo o timeout al instalar APK." >&2
    exit 1
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
