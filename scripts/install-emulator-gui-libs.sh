#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="${HOME}/.local/emu-libs"
WORK_DIR="/tmp/emu-missing-libs"

mkdir -p "${BASE_DIR}" "${WORK_DIR}"
cd "${WORK_DIR}"

# Packages required to run Android emulator with window in this environment.
apt download \
  libpulse0 \
  libapparmor1 \
  libasyncns0 \
  libsndfile1 \
  libnss3 \
  libnspr4 \
  libxkbfile1 \
  libxkbcommon-x11-0 \
  libxcb-cursor0 \
  libxcb-icccm4 \
  libxcb-image0 \
  libxcb-keysyms1 \
  libxcb-render-util0 \
  libxcb-xinerama0 \
  libxcb-xinput0 \
  libflac12t64 \
  libmpg123-0t64 \
  libvorbis0a \
  libvorbisenc2 \
  libogg0 \
  libopus0 \
  libmp3lame0

for deb in ./*.deb; do
  dpkg-deb -x "${deb}" "${BASE_DIR}"
done

echo "Librerias GUI instaladas en: ${BASE_DIR}"
