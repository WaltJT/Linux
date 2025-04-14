#!/bin/bash

# Opciones del menú con iconos de Nerd Fonts
OPTIONS="󱄋. - Recargar Hyprland\n󰝪. - Reiniciar Waybar\n. - Apagar\n. - Reiniciar\n. - Cerrar Sesión"

# Mostrar el menú y guardar la selección del usuario
SELECCION=$(echo -e $OPTIONS | wofi -dmenu -i -p "Menú del Sistema")

# Realizar una acción en función de la selección
case "$SELECCION" in
    "󱄋. - Recargar Hyprland")
        hyprctl reload
        ;;
    "󰝪. - Reiniciar Waybar")
        killall waybar && waybar &
        ;;
    ". - Cerrar Sesión")
        hyprctl dispatch exit
        ;;
    ". - Apagar")
        systemctl poweroff
        ;;
    ". - Reiniciar")
        systemctl reboot
        ;;
    #"襤 Hibernar")
    #    systemctl hibernate
    #    ;;
    *)
        # Si se cierra el menú sin seleccionar nada, no hace nada.
        exit 0
        ;;
esac

