#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$HOME/.dotfiles"

echo "Linking fish config..."
ln -sf "$DOTFILES/fish/config.fish" "$HOME/.config/fish/config.fish"

echo "Linking wezterm config..."
ln -sf "$DOTFILES/.wezterm.lua" "$HOME/.wezterm.lua"

echo "Done."
