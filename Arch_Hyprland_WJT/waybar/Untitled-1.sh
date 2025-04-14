#!/bin/bash

# Configuración
WOFI_WIDTH=400
WOFI_LINES=5

# Función para mostrar/ocultar contraseña
get_password() {
    SSID="$1"
    PASSWORD_VISIBLE="false"
    PASSWORD_VISIBLE="true"
    PASSWORD=""
    
    while true; do
        ACTION=$(echo -e "🔒 Contraseña oculta\n🌐 Ver contraseña\n🚀 Conectar\n❌ Cancelar" | \
            wofi --dmenu --prompt "Contraseña para $SSID" --width $WOFI_WIDTH --lines 4)
        
        case "$ACTION" in
            "🔒 Contraseña oculta")
                PASSWORD=$(wofi --dmenu --password --prompt "Escribe contraseña" --width $WOFI_WIDTH)
                PASSWORD_VISIBLE="false"
                ;;
            "🌐 Ver contraseña")
                PASSWORD=$(wofi --dmenu --prompt "Contraseña visible" --width $WOFI_WIDTH --text "$PASSWORD")
                PASSWORD_VISIBLE="true"
                ;;
            "🚀 Conectar")
                [ -n "$PASSWORD" ] && break
                ;;
            *)
                exit 0
                ;;
        esac
    done
    
    echo "$PASSWORD"
}

# Obtener redes WiFi
NETWORKS=$(nmcli --fields "SECURITY,SSID" device wifi list | sed 1d | awk -F'  +' '{
    if ($1 ~ /WPA/) print "🔒 " $2; 
    else print "🌍 " $2
}')

# Mostrar selector
CHOSEN_NETWORK=$(echo "$NETWORKS" | wofi --dmenu --prompt "Redes WiFi" --width $WOFI_WIDTH --lines $WOFI_LINES)

if [ -n "$CHOSEN_NETWORK" ]; then
    SSID=$(echo "$CHOSEN_NETWORK" | sed -E 's/^[^[:alnum:]]*//')
    
    if [[ "$CHOSEN_NETWORK" =~ "🔒" ]]; then
        PASSWORD=$(get_password "$SSID")
        [ -n "$PASSWORD" ] && nmcli device wifi connect "$SSID" password "$PASSWORD"
    else
        nmcli device wifi connect "$SSID"
    fi
fi

#########################################################################################################

#!/bin/bash

# Configuración
WOFI_WIDTH=400
WOFI_LINES=8
ACTIVE_COLOR="#7aa2f7"

# Función principal
main_menu() {
    while true; do
        # Obtener conexión activa
        ACTIVE_CONN=$(nmcli -t -f NAME,DEVICE connection show --active | grep 'wifi' | cut -d: -f1)
        
        # Menú principal
        CHOICE=$(echo -e "📶 Conectarse a red\n🚫 Desconectar WiFi actual\n🧹 Olvidar red guardada\n🔄 Rescanear redes\n⚙️ Administrar conexiones\n❌ Salir" | \
            wofi --dmenu --prompt "WiFi Manager (${ACTIVE_CONN:-Desconectado})" --width $WOFI_WIDTH --lines $WOFI_LINES)

        case "$CHOICE" in
            "📶 Conectarse a red")
                connect_menu
                ;;
            "🚫 Desconectar WiFi actual")
                [ -n "$ACTIVE_CONN" ] && nmcli connection down "$ACTIVE_CONN"
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

    # Mostrar menú
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
                    connect_to_wifi "$SSID" --password
                else
                    connect_to_wifi "$SSID"
                fi
            fi
            ;;
    esac
}

# Conectar a WiFi
connect_to_wifi() {
    SSID="$1"
    
    if [[ "$2" == "--password" ]]; then
        PASSWORD=$(wofi --dmenu --password --prompt "Contraseña para $SSID" --width $WOFI_WIDTH)
        [ -z "$PASSWORD" ] && return
        
        # Intentar conexión
        RESULT=$(nmcli device wifi connect "$SSID" password "$PASSWORD" 2>&1)
    else
        RESULT=$(nmcli device wifi connect "$SSID" 2>&1)
    fi

    if echo "$RESULT" | grep -q "Error"; then
        notify-send "Error de conexión" "$RESULT" --urgency=critical
    else
        notify-send "Conexión exitosa" "Conectado a $SSID"
    fi
}

# Olvidar red guardada
forget_network() {
    # Obtener redes guardadas
    SAVED_NETWORKS=$(nmcli -t -f NAME connection show | grep -v '^lo$\|^eth0$\|^wlan0$')
    
    # Mostrar menú
    SELECTED=$(echo "$SAVED_NETWORKS" | wofi --dmenu --prompt "Selecciona red a olvidar" --width $WOFI_WIDTH --lines $WOFI_LINES)
    
    [ -n "$SELECTED" ] && nmcli connection delete "$SELECTED" && \
        notify-send "Red olvidada" "Se eliminó $SELECTED"
}

# Ejecutar
main_menu