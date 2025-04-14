#!/bin/bash

# Archivo para almacenar el historial del portapapeles
HIST_FILE="$HOME/.cache/clipboard-history"
[ ! -f "$HIST_FILE" ] && touch "$HIST_FILE"

# Acción: Guarda el contenido del portapapeles al historial
xclip -o -selection clipboard | grep -v '^$' >> "$HIST_FILE"

# Eliminar duplicados
awk '!seen[$0]++' "$HIST_FILE" > "${HIST_FILE}.tmp" && mv "${HIST_FILE}.tmp" "$HIST_FILE"

# Limitar el historial a 100 entradas
tail -n 100 "$HIST_FILE" > "${HIST_FILE}.tmp" && mv "${HIST_FILE}.tmp" "$HIST_FILE"

# Mostrar el historial con Rofi
selected=$(tac "$HIST_FILE" | rofi -dmenu -i -p "Clipboard History")

# Copiar la selección al portapapeles
[ -n "$selected" ] && echo -n "$selected" | xclip -selection clipboard
