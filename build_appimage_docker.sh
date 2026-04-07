#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="devicemanager-appimage-builder:ubuntu22.04"

cd "$PROJECT_DIR"

echo "[1/3] Building Docker image (Ubuntu 22.04)..."
docker build -f Dockerfile.appimage -t "$IMAGE_NAME" .

echo "[2/3] Building AppImage inside container..."
docker run --rm \
  -v "$PROJECT_DIR:/workspace" \
  -w /workspace \
  "$IMAGE_NAME" \
  bash -lc "./build_appimage.sh"

echo "[3/3] Done. AppImage is in project root."
