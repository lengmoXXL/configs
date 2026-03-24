#!/bin/bash
set -e

INSTALL_DIR="$HOME/.local/bin"

echo "==> Installing bash-language-server..."
npm install -g bash-language-server

echo "==> Linking to $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"
ln -sf "$(which bash-language-server)" "$INSTALL_DIR/bash-language-server"

echo "==> Done! bash-language-server installed"