#!/bin/bash

# Configuración
WOFI_WIDTH=400
WOFI_LINES=8
ACTIVE_COLOR="#7aa2f7"

# Función para obtener conexión WiFi activa
get_active_wifi() {
    nmcli -t -f NAME,DEVICE,TYPE connection show --active | awk -F: '/wifi/ {print $1}' | head -n 1
}

# Función para conectar
connect_to_wifi() {
    local SSID="$1"
    local PASSWORD="${2:-}"
    
    # Verificar si ya existe la conexión
    if nmcli -g NAME connection show | grep -q "^${SSID}$"; then
        # Conexión guardada
        RESULT=$(nmcli connection up "$SSID" 2>&1)
    else
        # Nueva conexión
        if [ -z "$PASSWORD" ]; then
            # Red abierta
            RESULT=$(nmcli device wifi connect "$SSID" 2>&1)
        else
            # Red protegida
            RESULT=$(nmcli device wifi connect "$SSID" password "$PASSWORD" 2>&1)
        fi
    fi

    if echo "$RESULT" | grep -q "Error"; then
        notify-send -u critical "Error de conexión" "$RESULT"
        return 1
    else
        notify-send "Conexión exitosa" "Conectado a $SSID"
        return 0
    fi
}

# Función para desconectar
disconnect_wifi() {
    local ACTIVE_CONN=$(get_active_wifi)
    if [ -n "$ACTIVE_CONN" ]; then
        RESULT=$(nmcli connection down "$ACTIVE_CONN" 2>&1)
        if echo "$RESULT" | grep -q "Error"; then
            notify-send -u critical "Error al desconectar" "$RESULT"
        else
            notify-send "Desconectado" "Se ha desconectado de $ACTIVE_CONN"
        fi
    else
        notify-send -u low "Información" "No hay conexión WiFi activa"
    fi
}

# Menú principal
main_menu() {
    while true; do
        ACTIVE_CONN=$(get_active_wifi)
        
        CHOICE=$(echo -e "📶 Conectarse a red\n🚫 Desconectar (${ACTIVE_CONN:-ninguna})\n🧹 Olvidar red guardada\n🔄 Rescanear redes\n⚙️ Administrar conexiones\n❌ Salir" | \
            wofi --dmenu --prompt "Gestión WiFi" --width $WOFI_WIDTH --lines $WOFI_LINES)

        case "$CHOICE" in
            "📶 Conectarse a red")
                connect_menu
                ;;
            "🚫 Desconectar ("*)
                nmcli radio wifi off
                ;;
            "🧹 Olvidar red guardada")
                forget_network
                ;;
            "🔄 Rescanear redes")
                nmcli device wifi rescan
                notify-send "WiFi" "Escaneo de redes completado"
                ;;
            "⚙️ Administrar conexiones")
                nm-connection-editor &
                ;;
            *)
                exit 0
                ;;
        esac
    done
}

# Menú de conexión
connect_menu() {
    # Obtener redes disponibles
    NETWORKS=$(nmcli --fields "SECURITY,SSID" device wifi list | sed 1d | awk -F'  +' '{
        if ($1 ~ /WPA/) print "🔒 " $2; 
        else print "🌍 " $2
    }')

    SELECTED=$(echo -e "$NETWORKS\n📡 Conectar a red oculta" | \
        wofi --dmenu --prompt "Selecciona red" --width $WOFI_WIDTH --lines $WOFI_LINES)

    case "$SELECTED" in
        "📡 Conectar a red oculta")
            SSID=$(wofi --dmenu --prompt "Ingresa SSID" --width $WOFI_WIDTH)
            [ -n "$SSID" ] && connect_to_wifi "$SSID"
            ;;
        *)
            if [[ -n "$SELECTED" ]]; then
                SSID=$(echo "$SELECTED" | sed -E 's/^[^[:alnum:]]*//')
                if [[ "$SELECTED" =~ "🔒" ]]; then
                    password_dialog "$SSID"
                else
                    connect_to_wifi "$SSID"
                fi
            fi
            ;;
    esac
}

# Diálogo de contraseña
password_dialog() {
    local SSID="$1"
    local PASSWORD=""
    local SHOW=false
    
    while true; do
        if $SHOW; then
            MENU="👁️ Contraseña: $PASSWORD\n👀 Ocultar contraseña\n🚀 Conectar\n↩️ Volver"
        else
            MENU="👁️🗨️ Contraseña oculta\n👀 Mostrar contraseña\n🚀 Conectar\n↩️ Volver"
        fi

        CHOICE=$(echo -e "$MENU" | wofi --dmenu --prompt "WiFi: $SSID" --width $WOFI_WIDTH --lines 4)

        case "$CHOICE" in
            "👁️🗨️ Contraseña oculta")
                PASSWORD=$(wofi --dmenu --password --prompt "Contraseña para $SSID" --width $WOFI_WIDTH)
                ;;
            "👁️ Contraseña: "*)
                PASSWORD=$(wofi --dmenu --prompt "Editar contraseña" --width $WOFI_WIDTH --text "$PASSWORD")
                ;;
            "👀 Mostrar contraseña")
                SHOW=true
                ;;
            "👀 Ocultar contraseña")
                SHOW=false
                ;;
            "🚀 Conectar")
                if [ -n "$PASSWORD" ]; then
                    connect_to_wifi "$SSID" "$PASSWORD" && return 0
                fi
                ;;
            *)
                return 1
                ;;
        esac
    done
}

# Olvidar red
forget_network() {
    SAVED=$(nmcli -t -f NAME connection show | grep -v -E '^lo$|^eth[0-9]+$|^wlan[0-9]+$')
    SELECTED=$(echo "$SAVED" | wofi --dmenu --prompt "Red a olvidar" --width $WOFI_WIDTH --lines $WOFI_LINES)
    
    if [ -n "$SELECTED" ]; then
        RESULT=$(nmcli connection delete "$SELECTED" 2>&1)
        if echo "$RESULT" | grep -q "Error"; then
            notify-send -u critical "Error al olvidar red" "$RESULT"
        else
            notify-send "Red olvidada" "Se eliminó $SELECTED"
        fi
    fi
}

# Ejecutar
main_menu
