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

cd "$DIR"

echo "==> Building system configuration"
darwin-rebuild build --flake ~/.maconfig#"$FLAKE_HOST"

SYSTEM="$(readlink "$DIR/result")"
if [ -z "$SYSTEM" ] || [ ! -x "$SYSTEM/activate" ]; then
  echo "Could not find built system at $DIR/result"
  exit 1
fi

echo "==> Activating system configuration (sudo required)"
# herdr and similar tools can recreate managed paths while the build runs.
backup_managed_config "$DIR"
sudo nix-env -p /nix/var/nix/profiles/system --set "$SYSTEM"
exec sudo "$SYSTEM/activate"
