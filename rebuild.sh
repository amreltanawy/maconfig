#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=scripts/backup-managed-config.sh
source "$DIR/scripts/backup-managed-config.sh"

ln -sfn "$DIR" ~/.maconfig

FLAKE_HOST="$(sed -nE 's/^[[:space:]]*darwinConfigurations\."([^"]+)".*/\1/p' "$DIR/flake.nix" | head -n1)"
if [ -z "$FLAKE_HOST" ]; then
  echo "Could not find darwinConfigurations host name in flake.nix."
  exit 1
fi

echo "==> Backing up existing configs that would be clobbered"
backup_managed_config "$DIR"

exec sudo darwin-rebuild switch --flake ~/.maconfig#"$FLAKE_HOST"
