#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_DIR="$PROJECT_DIR/tools"
APPDIR="$PROJECT_DIR/AppDir"
DIST_APP_DIR="$PROJECT_DIR/dist/DeviceManager"
APPIMAGE_PATTERN="$PROJECT_DIR/DeviceManager-*.AppImage"

cd "$PROJECT_DIR"

echo "[1/7] Building onedir bundle..."
"$PROJECT_DIR/build.sh"

if [[ ! -x "$DIST_APP_DIR/DeviceManager" ]]; then
  echo "Error: executable not found at $DIST_APP_DIR/DeviceManager"
  exit 1
fi

echo "[2/7] Preparing linuxdeploy..."
mkdir -p "$TOOLS_DIR"

if [[ ! -x "$TOOLS_DIR/linuxdeploy-x86_64.AppImage" ]]; then
  wget -O "$TOOLS_DIR/linuxdeploy-x86_64.AppImage" \
    https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage
  chmod +x "$TOOLS_DIR/linuxdeploy-x86_64.AppImage"
fi

echo "[3/7] Cleaning previous AppDir and AppImage..."
rm -rf "$APPDIR"
rm -f $APPIMAGE_PATTERN 2>/dev/null || true

echo "[4/7] Creating AppDir layout..."
mkdir -p "$APPDIR/usr/bin" \
         "$APPDIR/usr/share/applications" \
         "$APPDIR/usr/share/icons/hicolor/scalable/apps"

cp "$DIST_APP_DIR/DeviceManager" "$APPDIR/usr/bin/DeviceManager"
if [[ -d "$DIST_APP_DIR/_internal" ]]; then
  cp -r "$DIST_APP_DIR/_internal" "$APPDIR/usr/bin/_internal"
fi

cp "$PROJECT_DIR/assets/app_icon.svg" \
   "$APPDIR/usr/share/icons/hicolor/scalable/apps/devicemanager.svg"

echo "[5/7] Writing AppImage desktop entry..."
cat > "$APPDIR/usr/share/applications/DeviceManager.desktop" <<'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=DeviceManager
Comment=USB and serial device monitor
Terminal=false
Categories=Utility;Development;
Exec=DeviceManager
Icon=devicemanager
StartupWMClass=DeviceManager
EOF

echo "[6/7] Running linuxdeploy (without Qt plugin)..."

LINUXDEPLOY_BIN="$TOOLS_DIR/linuxdeploy-x86_64.AppImage"
if [[ ! -x "$LINUXDEPLOY_BIN" ]]; then
  echo "Error: linuxdeploy AppImage not found at $LINUXDEPLOY_BIN"
  exit 1
fi

# Always use extracted AppRun to avoid FUSE dependency in containers.
rm -rf "$TOOLS_DIR/squashfs-root"
(
  cd "$TOOLS_DIR"
  "$LINUXDEPLOY_BIN" --appimage-extract >/dev/null
)

"$TOOLS_DIR/squashfs-root/AppRun" \
  --appdir "$APPDIR" \
  --desktop-file "$APPDIR/usr/share/applications/DeviceManager.desktop" \
  --icon-file "$APPDIR/usr/share/icons/hicolor/scalable/apps/devicemanager.svg" \
  --output appimage

echo "[7/7] Done."
ls -1 "$PROJECT_DIR"/DeviceManager-*.AppImage
