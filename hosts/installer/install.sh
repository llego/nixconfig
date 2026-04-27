#!/usr/bin/env bash
set -euo pipefail

FLAKE_DIR="/tmp/nixconfig"

echo "==> Cloning nixconfig..."
git clone git@github.com:llego/nixconfig.git "$FLAKE_DIR"
cd "$FLAKE_DIR"

echo "==> Partitioning and formatting disk (you will be prompted for a LUKS passphrase)..."
sudo disko --mode destroy,format,mount hosts/laptop/disk-config.nix

echo "==> Installing NixOS..."
sudo nixos-install --flake .#laptop --no-root-passwd

echo ""
echo "==> Done. Review the output above for errors."
echo "    Then run: sudo reboot"
echo ""
echo "==> After first boot, on crisuflix:"
echo "    ssh-keyscan laptop.home   # grab new host key"
echo "    # add it to secrets/secrets.nix"
echo "    cd ~/nixconfig && agenix -r"
echo "    nixos-rebuild switch --flake .#laptop \\"
echo "      --build-host llego@crisuflix.home \\"
echo "      --target-host llego@laptop.home --sudo"
