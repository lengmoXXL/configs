#!/bin/bash
set -e

REPO_URL="https://github.com/lengmoXXL/mytask.git"
INSTALL_DIR="$HOME/.local/bin"
TMP_DIR=$(mktemp -d)
BINARY_NAME="mytask"

echo "==> Cloning repository..."
git clone "$REPO_URL" "$TMP_DIR/mytask"

echo "==> Building binary..."
cd "$TMP_DIR/mytask"
go build -o "$BINARY_NAME" ./cmd/mytask

echo "==> Installing to $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"
mv "$BINARY_NAME" "$INSTALL_DIR/"

echo "==> Cleaning up..."
rm -rf "$TMP_DIR"

echo "==> Done! $BINARY_NAME installed to $INSTALL_DIR/$BINARY_NAME"
echo "Make sure $INSTALL_DIR is in your PATH"