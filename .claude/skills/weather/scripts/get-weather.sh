#!/usr/bin/env bash
set -euo pipefail

weather_desc() {
  case "$1" in
    0) echo "☀️  Despejado" ;;
    1) echo "🌤️  Mayormente despejado" ;;
    2) echo "⛅ Parcialmente nublado" ;;
    3) echo "☁️  Nublado" ;;
    45|48) echo "🌫️  Niebla" ;;
    51|53|55) echo "🌦️  Llovizna" ;;
    56|57) echo "🌧️  Llovizna helada" ;;
    61|63|65) echo "🌧️  Lluvia" ;;
    66|67) echo "🌧️  Lluvia helada" ;;
    71|73|75|77) echo "🌨️  Nieve" ;;
    80|81|82) echo "🌧️  Chubascos" ;;
    85|86) echo "🌨️  Chubascos de nieve" ;;
    95) echo "⛈️  Tormenta eléctrica" ;;
    96|99) echo "⛈️  Tormenta con granizo" ;;
    *) echo "❓ Desconocido" ;;
  esac
}

echo "Detectando ubicación por IP..." >&2
geo=$(curl -s --max-time 10 http://ip-api.com/json) || {
  echo "Error: no se pudo detectar la ubicación (¿hay conexión a internet?)" >&2
  exit 1
}

status=$(echo "$geo" | jq -r '.status // empty')
if [ "$status" != "success" ]; then
  echo "Error: no se pudo detectar la ubicación por IP." >&2
  exit 1
fi

lat=$(echo "$geo" | jq -r '.lat')
lon=$(echo "$geo" | jq -r '.lon')
city=$(echo "$geo" | jq -r '.city')
region=$(echo "$geo" | jq -r '.regionName')
country=$(echo "$geo" | jq -r '.country')

echo "Consultando clima para $city, $region, $country..." >&2
weather=$(curl -s --max-time 10 "https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&current=temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m,wind_direction_10m&hourly=temperature_2m,precipitation_probability,weather_code&forecast_days=1&timezone=auto") || {
  echo "Error: no se pudo obtener el clima de Open-Meteo." >&2
  exit 1
}

if [ -z "$(echo "$weather" | jq -r '.current // empty')" ]; then
  echo "Error: respuesta inesperada de Open-Meteo:" >&2
  echo "$weather" >&2
  exit 1
fi

cur_time=$(echo "$weather" | jq -r '.current.time')
cur_temp=$(echo "$weather" | jq -r '.current.temperature_2m')
cur_feels=$(echo "$weather" | jq -r '.current.apparent_temperature')
cur_humidity=$(echo "$weather" | jq -r '.current.relative_humidity_2m')
cur_precip=$(echo "$weather" | jq -r '.current.precipitation')
cur_code=$(echo "$weather" | jq -r '.current.weather_code')
cur_wind_speed=$(echo "$weather" | jq -r '.current.wind_speed_10m')
cur_wind_dir=$(echo "$weather" | jq -r '.current.wind_direction_10m')
temp_unit=$(echo "$weather" | jq -r '.current_units.temperature_2m')
wind_unit=$(echo "$weather" | jq -r '.current_units.wind_speed_10m')
precip_unit=$(echo "$weather" | jq -r '.current_units.precipitation')

cur_desc=$(weather_desc "$cur_code")

echo ""
echo "=================================================="
echo " CLIMA ACTUAL - ${city}, ${region}, ${country}"
echo "=================================================="
printf "%-20s %s\n" "Condición:" "$cur_desc"
printf "%-20s %s%s\n" "Temperatura:" "$cur_temp" "$temp_unit"
printf "%-20s %s%s\n" "Sensación térmica:" "$cur_feels" "$temp_unit"
printf "%-20s %s%%\n" "Humedad:" "$cur_humidity"
printf "%-20s %s%s (%s°)\n" "Viento:" "$cur_wind_speed" "$wind_unit" "$cur_wind_dir"
printf "%-20s %s%s\n" "Precipitación:" "$cur_precip" "$precip_unit"
echo "--------------------------------------------------"
echo " PRÓXIMAS HORAS"
echo "--------------------------------------------------"
printf "%-8s %-10s %-8s %s\n" "Hora" "Temp" "Prob." "Condición"

start_idx=$(echo "$weather" | jq --arg now "$cur_time" '
  [.hourly.time | to_entries[] | select(.value >= $now) | .key] | first // 0
')

echo "$weather" | jq -r --argjson start "$start_idx" '
  .hourly.time as $t | .hourly.temperature_2m as $temp | .hourly.precipitation_probability as $prob | .hourly.weather_code as $code |
  range($start; ($start + 6)) | select(. < ($t | length)) |
  "\($t[.])|\($temp[.])|\($prob[.])|\($code[.])"
' | while IFS='|' read -r row_time row_temp row_prob row_code; do
  hour=$(echo "$row_time" | cut -dT -f2)
  desc=$(weather_desc "$row_code")
  printf "%-8s %-10s %-8s %s\n" "$hour" "${row_temp}${temp_unit}" "${row_prob}%" "$desc"
done

echo "=================================================="
