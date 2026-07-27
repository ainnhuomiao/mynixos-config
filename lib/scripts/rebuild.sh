#!/usr/bin/env bash

set -euo pipefail

PAMT=sudo

# 1. Dynamically discover hosts from flake
echo "🕵️ Discovering hosts..."
# Extracting keys from nixosConfigurations using nix flake show --json and jq
if ! hosts_json=$(nix flake show --json 2>/dev/null); then
  echo "❌ Failed to discover NixOS configurations. Ensure 'nix flake show' runs successfully." >&2
  exit 1
fi
hosts=($(echo "$hosts_json" | jq -r '.nixosConfigurations | keys[]'))

if [ ${#hosts[@]} -eq 0 ]; then
  echo "❌ No NixOS configurations found in flake or 'jq' failed to parse." >&2
  exit 1
fi

echo "Which device do you want to rebuild?"
for i in "${!hosts[@]}"; do
  echo "$((i + 1)). ${hosts[$i]}"
done

read -p $'\e[1;32mEnter your choice (number): \e[0m' -r choice

# Validate choice
if [[ ! $choice =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "${#hosts[@]}" ]; then
  echo "❌ Invalid choice, please try again."
  exit 1
fi

selected_host="${hosts[$((choice - 1))]}"

# 2. Rebuild the selected host
echo "🚀 Rebuilding $selected_host..."
$PAMT nixos-rebuild switch --flake ".#$selected_host" 2>&1 | nom
