monitor_clipboard() {
    LAST_HASH=""
    while true; do
        # Solo captura texto (ignora imágenes)
        CURRENT_TEXT=$(wl-paste --no-newline 2>/dev/null || xclip -o -selection clipboard 2>/dev/null)
        
        # Verifica si es texto válido (no binario/imagen)
        if [[ -n "$CURRENT_TEXT" ]] && ! echo "$CURRENT_TEXT" | grep -q "[^[:print:][:space:]]"; then
            CURRENT_HASH=$(echo "$CURRENT_TEXT" | sha256sum | cut -d' ' -f1)
            if [[ "$CURRENT_HASH" != "$LAST_HASH" ]]; then
                echo "text::$CURRENT_TEXT" >> "$HISTORIAL_FILE"
                LAST_HASH="$CURRENT_HASH"
            fi
        fi

        # Limitar historial (opcional)
        tail -n "$MAX_ENTRIES" "$HISTORIAL_FILE" > "$HISTORIAL_FILE.tmp"
        mv "$HISTORIAL_FILE.tmp" "$HISTORIAL_FILE"
        sleep 1
    done
}