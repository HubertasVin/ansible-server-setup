#!/usr/bin/env bash
# filepath: back-end/k8s/seed-data.sh
# Populates the hostPath data directory with the seed JSON files.
#
# Usage:
#   SEED_SRC=~/apps/detourpilot/back-end/data \
#   DATA_DIR=/var/lib/detourpilot/data \
#   ./seed-data.sh
#
# The defaults assume you cloned the repo at ~/apps/detourpilot and
# the back-end deployment mounts /var/lib/detourpilot/data at /app/data.
set -euo pipefail

SEED_SRC="${SEED_SRC:-$(dirname "$0")/../data}"
DATA_DIR="${DATA_DIR:-/var/lib/detourpilot/data}"
NONROOT_UID="${NONROOT_UID:-65532}"

if [[ ! -d "$SEED_SRC" ]]; then
  echo "✗ Seed source not found: $SEED_SRC" >&2
  echo "  Set SEED_SRC=/path/to/back-end/data and try again." >&2
  exit 1
fi

echo "→ Ensuring $DATA_DIR exists"
sudo mkdir -p "$DATA_DIR"
sudo chown -R "$NONROOT_UID:$NONROOT_UID" "$DATA_DIR"
sudo chmod 755 "$DATA_DIR"

copied=0
skipped=0
for f in ranking.json places.json trips.json; do
  src="$SEED_SRC/$f"
  dst="$DATA_DIR/$f"
  if [[ ! -s "$src" ]]; then
    echo "  ! $f missing or empty in seed source, skipping"
    skipped=$((skipped + 1))
    continue
  fi
  if [[ -s "$dst" ]]; then
    echo "  · $f already present, skipping"
    skipped=$((skipped + 1))
    continue
  fi
  sudo cp "$src" "$dst"
  sudo chown "$NONROOT_UID:$NONROOT_UID" "$dst"
  sudo chmod 644 "$dst"
  echo "  ✓ seeded $f ($(stat -c %s "$dst") bytes)"
  copied=$((copied + 1))
done

echo "✓ Done. copied=$copied skipped=$skipped"
ls -la "$DATA_DIR"
