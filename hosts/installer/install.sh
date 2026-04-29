#!/usr/bin/env bash
set -euo pipefail

NIXCONFIG="/etc/nixconfig"
CRISUFLIX="llego@crisuflix.home"

echo "==> Partitioning and formatting disk (you will be prompted for a LUKS passphrase)..."
sudo disko --mode destroy,format,mount "$NIXCONFIG/hosts/laptop/disk-config.nix"

echo "==> Restoring SSH host keys from crisuflix (preserves agenix decryption)..."
sudo mkdir -p /mnt/etc/ssh
ssh "$CRISUFLIX" 'cat ~/laptop-ssh-host-keys.tar' \
  | sudo tar -C /mnt/etc/ssh -xf -
sudo chmod 600 /mnt/etc/ssh/ssh_host_*_key
sudo chmod 644 /mnt/etc/ssh/ssh_host_*_key.pub

echo "==> Installing NixOS..."
sudo nixos-install --flake "$NIXCONFIG#laptop" --no-root-passwd

echo ""
echo "==> Done. Review the output above for errors."
echo "    Then run: sudo reboot"
echo ""
echo "==> After first boot:"
echo "    sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 /dev/nvme0n1p2"
