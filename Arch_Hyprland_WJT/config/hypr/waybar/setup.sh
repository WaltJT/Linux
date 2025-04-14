#!/bin/sh

mkdir -p ~/.config/waybar
cp -r config-gitlab.jsonc style.css config.jsonc scripts/ ~/.config/waybar

echo "Waybar Configuration Done Successfully"

