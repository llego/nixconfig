#!/usr/bin/env bash
# Quick test script to verify the flake builds correctly

set -e

echo "=== Testing Nix Flake for RuuviCollector ==="
echo

# Check flake
echo "1. Checking flake validity..."
nix flake check --no-build
echo "✓ Flake is valid"
echo

# Show flake info
echo "2. Showing flake outputs..."
nix flake show
echo

# Try building (but don't install)
echo "3. Building package for current system..."
nix build .#ruuvi-collector --dry-run
echo "✓ Build derivation is valid"
echo

echo "=== All checks passed! ==="
echo
echo "To actually build:"
echo "  nix build .#ruuvi-collector"
echo
echo "To run:"
echo "  nix run .#ruuvi-collector"
echo
echo "To use in NixOS, see NIX_README.md for configuration examples."
