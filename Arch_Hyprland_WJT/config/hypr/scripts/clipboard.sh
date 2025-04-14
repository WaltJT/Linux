#!/bin/bash

# Configuración
HISTORIAL_FILE="$HOME/.clipboard_history"
MAX_ENTRIES=20
#IMAGE_DIR="$HOME/.cache/clipboard_img"
#mkdir -p "$IMAGE_DIR"

# Elegir el mejor frontend disponible
FRONTEND=$(command -v wofi || command -v rofi || echo "dmenu")
NOTIFY=$(command -v notify-send)

# Función mejorada para pegar
#paste_content() {
#    if [[ "$1" == image::* ]]; then
#        local img_path="${1#image::}"
#        if [[ -f "$img_path" ]]; then
#            # Usar xclip para imágenes
#            xclip -selection clipboard -t image/png -i "$img_path" 2>/dev/null
#           $NOTIFY "📋 Imagen lista para pegar" "$(basename "$img_path")" -i "$img_path"
#        fi
#    else
    #    local text="${1#text::}"
    #    echo -n "$text" | xclip -selection clipboard 2>/dev/null
    #    $NOTIFY "📋 Texto copiado" "${text:0:50}..."
#    fi
#}

# Monitoreo mejorado
monitor_clipboard() {
    LAST_HASH=""
    while true; do
        # Verificar imágenes
        if wl-paste --list-types 2>/dev/null | grep -qi "image"; then
            IMG_PATH="$IMAGE_DIR/img_$(date +%s%N).png"
            if wl-paste | convert - PNG:"$IMG_PATH" 2>/dev/null && [[ -s "$IMG_PATH" ]]; then
                echo "image::$IMG_PATH" >> "$HISTORIAL_FILE"
                LAST_HASH=$(sha256sum "$IMG_PATH" | cut -d' ' -f1)
            fi
        else
            # Manejar texto
            CURRENT_TEXT=$(wl-paste --no-newline 2>/dev/null || xclip -o -selection clipboard 2>/dev/null)
            if [[ -n "$CURRENT_TEXT" ]]; then
                CURRENT_HASH=$(echo "$CURRENT_TEXT" | sha256sum | cut -d' ' -f1)
                if [[ "$CURRENT_HASH" != "$LAST_HASH" ]]; then
                    echo "text::$CURRENT_TEXT" >> "$HISTORIAL_FILE"
                    LAST_HASH="$CURRENT_HASH"
                fi
            fi
        fi

        # Limitar historial
        tail -n "$MAX_ENTRIES" "$HISTORIAL_FILE" > "$HISTORIAL_FILE.tmp"
        mv "$HISTORIAL_FILE.tmp" "$HISTORIAL_FILE"
        sleep 1
    done
}

# Interfaz de selección
show_history() {
    # Filtrar solo entradas de texto
    if [[ ! -s "$HISTORIAL_FILE" ]] || ! grep -q "^text::" "$HISTORIAL_FILE"; then
        $NOTIFY "📋 Portapapeles" "Historial vacío" && return
    fi

    # Generar lista solo con texto
    LIST=$(grep "^text::" "$HISTORIAL_FILE" | tac | awk '{
        print "📝 " substr($0, 7, 50) (length($0)>50?"...":"")
    }')

    # Mostrar selección
    SELECTION=$(echo "$LIST" | $FRONTEND -dmenu -i -p "Portapapeles - Historial de copiado:" -kb-custom-1 "Ctrl+Delete")

    if [[ -n "$SELECTION" ]]; then
        # Obtener el texto original
        LINE_NUM=$(echo "$LIST" | grep -nF "$SELECTION" | cut -d: -f1)
        LINE=$(grep "^text::" "$HISTORIAL_FILE" | tac | sed -n "${LINE_NUM}p")

        # Manejar acciones
        case $? in
            0)  # Enter - Pegar
                paste_content "$LINE"
                ;;
            10) # Ctrl+Delete - Borrar
                sed -i "$(( $(grep -c "^text::" "$HISTORIAL_FILE") - LINE_NUM + 1 ))d" "$HISTORIAL_FILE"
                $NOTIFY "🗑️ Elemento borrado" ""
                ;;
        esac
    fi
}

# Opciones
# Iniciar/limpiar
case "$1" in
    "monitor") monitor_clipboard ;;
    "show")    show_history ;;
    "clear")   rm -f "$HISTORIAL_FILE" "$IMAGE_DIR"/* && $NOTIFY "🧹 Historial limpiado" ;;
    "delete")
        mapfile -t HISTORIAL < <(tac "$HISTORIAL_FILE")
        LIST=()
        for LINE in "${HISTORIAL[@]}"; do
            [[ "$LINE" == text::* ]] && LIST+=("📝 ${LINE#text::}")
        done

        if [[ "$FRONTEND" == *wofi* ]]; then
            SELECTIONS=$(printf '%s\n' "${LIST[@]}" | $FRONTEND -dmenu -multi-select -p "Eliminar del historial:")
        elif [[ "$FRONTEND" == *wofi* ]]; then
            SELECTIONS=$(printf '%s\n' "${LIST[@]}" | $FRONTEND --dmenu --allow-markup --multiple --prompt "Eliminar del historial:")
        else
            SELECTIONS=$(printf '%s\n' "${LIST[@]}" | $FRONTEND -dmenu -p "Eliminar del historial:")
        fi

        [[ -z "$SELECTIONS" ]] && exit 0
        IFS=$'\n' read -r -d '' -a SELECTED <<< "$(printf "%s\0" "$SELECTIONS")"

        for SEL in "${SELECTED[@]}"; do
            for i in "${!HISTORIAL[@]}"; do
                LINE="📝 ${HISTORIAL[$i]#text::}"
                if [[ "$LINE" == "$SEL" ]]; then
                    LINE_NUM=$((${#HISTORIAL[@]} - i))
                    sed -i "${LINE_NUM}d" "$HISTORIAL_FILE"
                    $NOTIFY "🗑️ Entrada eliminada" "${LINE:0:50}..."
                    break
                fi
            done
        done
        ;;
    *) echo "Uso: $0 [monitor|show|clear|delete]" ;;
esac
