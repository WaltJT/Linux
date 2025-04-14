#!/bin/bash

HISTORIAL_FILE="$HOME/.clipboard_history"
FRONTEND=$(command -v wofi || command -v rofi || echo "dmenu")
NOTIFY=$(command -v notify-send)

notify() {
    [[ -n "$NOTIFY" ]] && $NOTIFY "$1" "$2"
}

delete_entries() {
    [[ ! -s "$HISTORIAL_FILE" ]] && notify "📋 Portapapeles" "Historial vacío" && exit 0

    mapfile -t HISTORIAL < <(tac "$HISTORIAL_FILE")
    LIST=()
    for LINE in "${HISTORIAL[@]}"; do
        [[ "$LINE" == text::* ]] && LIST+=("📝 ${LINE#text::}")
    done

    # Selección múltiple en wofi / wofi
    if [[ "$FRONTEND" == *wofi* ]]; then
        SELECTIONS=$(printf '%s\n' "${LIST[@]}" | $FRONTEND -dmenu -multi-select -p "Eliminar del historial:")
    elif [[ "$FRONTEND" == *wofi* ]]; then
        SELECTIONS=$(printf '%s\n' "${LIST[@]}" | $FRONTEND --dmenu --allow-markup --multiple --prompt "Eliminar del historial:")
    else
        # dmenu no soporta selección múltiple
        SELECTIONS=$(printf '%s\n' "${LIST[@]}" | $FRONTEND -dmenu -p "Eliminar del historial:")
    fi

    [[ -z "$SELECTIONS" ]] && exit 0

    # Convertir selecciones a array
    IFS=$'\n' read -r -d '' -a SELECTED <<< "$(printf "%s\0" "$SELECTIONS")"

    for SEL in "${SELECTED[@]}"; do
        for i in "${!HISTORIAL[@]}"; do
            LINE="📝 ${HISTORIAL[$i]#text::}"
            if [[ "$LINE" == "$SEL" ]]; then
                LINE_NUM=$((${#HISTORIAL[@]} - i))
                sed -i "${LINE_NUM}d" "$HISTORIAL_FILE"
                notify "🗑️ Entrada eliminada" "${LINE:0:50}..."
                break
            fi
        done
    done
}

delete_entries
