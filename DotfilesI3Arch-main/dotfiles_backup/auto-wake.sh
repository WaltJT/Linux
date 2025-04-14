#!/bin/bash

# Obtener la hora actual en formato de 24 horas (solo la parte de la hora)
current_hour=$(date +%H)

# Configurar la hora de encendido automático dependiendo de la hora actual
if [ "$current_hour" -ge 0 ] && [ "$current_hour" -lt 8 ]; then
    # Si es antes de las 8:00 AM, programamos el encendido para las 8:00 AM del día siguiente
    wake_time=$(date +%s -d 'tomorrow 8:00')
else
    # Si es después de las 8:00 AM, programamos el encendido para las 8:00 AM del mismo día
    wake_time=$(date +%s -d 'today 8:00')
fi

# Imprimir el tiempo programado
echo "Configurando el encendido a las $(date -d @$wake_time)"

# Escribir la hora en el archivo wakealarm para que el sistema despierte
echo $wake_time | sudo tee /sys/class/rtc/rtc0/wakealarm > /dev/null

# Hibernar el sistema
systemctl hibernate

# Guardar la configuración de los monitores
exec --no-startup-id ~/.config/i3/config
