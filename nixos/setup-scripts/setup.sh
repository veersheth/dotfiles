#!/usr/bin/env bash

set -euo pipefail

backup_name="old-config-$(date +%F-%H%M%S)"

confirm() {
    read -rp "$1 [Y/n] " reply
    case "$reply" in
        [nN][oO]|[nN]) return 1 ;;
        *) return 0 ;;
    esac
}

if [[ -f configuration.nix ]]; then
    if confirm "Backup existing configuration.nix?"; then
        mv -i configuration.nix "$backup_name"
    fi
fi

if confirm "Copy /etc/nixos/configuration.nix?"; then
    sudo cp -i /etc/nixos/configuration.nix ./configuration.nix
fi

if confirm "Copy /etc/nixos/hardware-configuration.nix?"; then
    sudo cp -i /etc/nixos/hardware-configuration.nix ./hardware-configuration.nix
fi

if confirm "Switch to unstable channel?"; then
    sudo nix-channel --add https://channels.nixos.org/nixos-unstable nixos
fi
