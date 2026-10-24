#!/usr/bin/env bash
# Instala warp-reset en ~/.local/bin (sin sudo).
set -euo pipefail

DEST="${PREFIX:-$HOME/.local/bin}"
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

install -Dm755 "$SRC_DIR/warp-reset" "$DEST/warp-reset"
echo "Instalado en $DEST/warp-reset"

case ":$PATH:" in
  *":$DEST:"*) ;;
  *) echo "Ojo: $DEST no está en tu PATH. Agregá: export PATH=\"$DEST:\$PATH\"" ;;
esac
