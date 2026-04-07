#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$PROJECT_DIR/.venv"
DIST_DIR="$PROJECT_DIR/dist"
BUILD_DIR="$PROJECT_DIR/build"
SPEC_FILE="$PROJECT_DIR/DeviceManager.spec"

if command -v python >/dev/null 2>&1; then
  PYTHON_BIN="python"
elif command -v python3 >/dev/null 2>&1; then
  PYTHON_BIN="python3"
else
  echo "Error: neither python nor python3 is available"
  exit 1
fi

cd "$PROJECT_DIR"

echo "[1/5] Preparing virtual environment..."
if [[ ! -d "$VENV_DIR" ]]; then
  "$PYTHON_BIN" -m venv "$VENV_DIR"
fi

source "$VENV_DIR/bin/activate"

echo "[2/5] Installing dependencies..."
"$PYTHON_BIN" -m pip install --upgrade pip
pip install -r requirements.txt pyinstaller

echo "[3/5] Cleaning previous build artifacts..."
rm -rf "$DIST_DIR" "$BUILD_DIR" "$SPEC_FILE"

echo "[4/5] Building executable with PyInstaller..."
# Bundle libusb so PyUSB works in frozen builds when the .so is present at build time.
LIBUSB_SO=""
for candidate in \
  /usr/lib/x86_64-linux-gnu/libusb-1.0.so.0 \
  /lib/x86_64-linux-gnu/libusb-1.0.so.0 \
  /usr/lib/libusb-1.0.so.0; do
  if [[ -f "$candidate" ]]; then
    LIBUSB_SO="$candidate"
    break
  fi
done
PYINSTALLER_EXTRA=()
if [[ -n "$LIBUSB_SO" ]]; then
  echo "Bundling libusb: $LIBUSB_SO"
  PYINSTALLER_EXTRA+=(--add-binary "${LIBUSB_SO}:.")
fi

pyinstaller \
  --name DeviceManager \
  --windowed \
  --onedir \
  --noconfirm \
  --add-data "qml:qml" \
  --add-data "assets:assets" \
  "${PYINSTALLER_EXTRA[@]}" \
  main.py

echo "[5/5] Build completed."
echo "Executable path: $DIST_DIR/DeviceManager/DeviceManager"
