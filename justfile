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

# Build a NixOS configuration without creating a result symlink
build host="nixos":
    nom build --no-link ".#nixosConfigurations.{{host}}.config.system.build.toplevel"

# Show all flake outputs
show:
    nix flake show

# Enter the default development shell with nix-output-monitor
develop:
    nom develop

# List NixOS system generations
generations:
    nixos-rebuild list-generations

# Validate, format, and switch with nix-output-monitor
rebuild-switch: check format
    NIX_CONFIG="experimental-features = nix-command flakes" bash ./lib/scripts/rebuild.sh

# Delete old user and system generations and collect unreferenced store paths
clean:
    nix-collect-garbage --delete-old
    sudo nix-collect-garbage --delete-old

# Partition and mount a target disk
disko:
    bash ./lib/scripts/disko.sh

# Install NixOS on the mounted target
install:
    bash ./lib/scripts/install.sh
