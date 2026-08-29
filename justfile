set shell := ["bash", "-euo", "pipefail", "-c"]

# List available recipes
[default]
help:
    @just --list

# Update all flake inputs with nix-output-monitor
update:
    nix flake update --log-format internal-json -v 2>&1 | nom --json

# Check all flake outputs with nix-output-monitor
check:
    nix flake check --fallback --log-format internal-json -v 2>&1 | nom --json

# Format the repository
format:
    nix fmt

# Build a NixOS configuration without activating it (nom output built in)
build host="nixos":
    nh os build . -H {{host}}

# Show all flake outputs
show:
    nix flake show

# Enter the default development shell with nix-output-monitor
develop:
    nom develop

# List NixOS system generations
# nh os info shows generation list from the system profile
# (replace the old `nixos-rebuild list-generations`)
generations:
    nh os info

# Validate, format, and switch via nh (nom output built in)
rebuild-switch: check format
    NIX_CONFIG="experimental-features = nix-command flakes" bash ./lib/scripts/rebuild.sh

# Complete system update: flake update → check → format → build+switch twice
# (registry snapshot needs two rebuilds to consume the new nixpkgs).
# See lib/scripts/update-rebuild-switch.sh for details; manual extra: just clean
update-rebuild-switch:
    bash ./lib/scripts/update-rebuild-switch.sh

# Delete old generations and gcroots, keeping 3 generations and 7 days of history
# nh clean all extends nix-collect-garbage with gcroot cleanup
# (replace the old `nix-collect-garbage --delete-old`)
clean:
    nh clean all --keep 3 --keep-since 7d

# Partition and mount a target disk
disko:
    bash ./lib/scripts/disko.sh

# Install NixOS on the mounted target
install:
    bash ./lib/scripts/install.sh
