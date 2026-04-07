#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$PROJECT_DIR/.venv"
DIST_DIR="$PROJECT_DIR/dist"
BUILD_DIR="$PROJECT_DIR/build"
SPEC_FILE="$PROJECT_DIR/DeviceManager.spec"

cd "$PROJECT_DIR"

echo "[1/5] Preparing virtual environment..."
if [[ ! -d "$VENV_DIR" ]]; then
  python -m venv "$VENV_DIR"
fi

source "$VENV_DIR/bin/activate"

echo "[2/5] Installing dependencies..."
python -m pip install --upgrade pip
pip install -r requirements.txt pyinstaller

echo "[3/5] Cleaning previous build artifacts..."
rm -rf "$DIST_DIR" "$BUILD_DIR" "$SPEC_FILE"

echo "[4/5] Building executable with PyInstaller..."
pyinstaller \
  --name DeviceManager \
  --windowed \
  --onedir \
  --noconfirm \
  --add-data "qml:qml" \
  --add-data "assets:assets" \
  main.py

echo "[5/5] Build completed."
echo "Executable path: $DIST_DIR/DeviceManager/DeviceManager"
