---
name: weather
description: Consulta el clima actual y el pronóstico de las próximas horas para la ubicación del usuario, detectada automáticamente por IP, usando Open-Meteo (sin API key). Úsala cuando pregunten por el clima, el tiempo, la temperatura, si va a llover, si hace falta paraguas o abrigo, o frases como "how's the weather", "clima ahora", "pronóstico de hoy".
---

# Weather (clima local)

Esta skill consulta el clima actual del usuario sin necesidad de configuración ni API keys.

## Cómo funciona

1. Detecta la ubicación aproximada a partir de la IP pública (`ip-api.com`).
2. Consulta el clima actual y el pronóstico de las próximas horas en Open-Meteo (`api.open-meteo.com`), sin API key.
3. Imprime una tabla con: condición, temperatura, sensación térmica, humedad, viento, precipitación, y pronóstico de las próximas ~6 horas.

## Uso

Ejecuta el script y muestra su salida al usuario tal cual (ya es una tabla legible):

```bash
bash .claude/skills/weather/scripts/get-weather.sh
```

Si el usuario pide algo puntual (por ejemplo, "¿necesito paraguas hoy?" o "¿hace frío?"), ejecuta el script y responde interpretando los datos de la tabla resultante — no inventes datos que no estén en la salida del script.

## Notas

- No requiere API key ni configuración: usa `ip-api.com` (geolocalización por IP) y `api.open-meteo.com` (clima), ambos gratuitos.
- Requiere `curl` y `jq` instalados en el sistema.
- Si el script falla (sin conexión, servicio caído), muestra el mensaje de error tal cual al usuario en lugar de inventar una respuesta.
