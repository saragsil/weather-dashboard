#!/bin/bash

# ============= CONFIGURATION =============
DASHBOARD=weather_dashboard.md         # Path to the generated Markdown file
LOG_FILE=logs/weather_log.txt          # Path to the log file
LOCATIONS=("37.9838,23.7275 Αθήνα" "40.6401,22.9444 Θεσσαλονίκη" "39.6650,20.8537 Ιωάννινα" "35.5138,24.0180 Χανιά" "51.5074,-0.1278 Λονδίνο" "38.9072,-77.0369 Washington") # "latitude,longitude Location"

# ============= START SCRIPT =============
# Redirect all output (stdout and stderr) to the log file
exec > >(tee -a "$LOG_FILE") 2>&1

echo "[$(date)] Starting Weather Dashboard Script"

# Generate Weather Dashboard Header
echo "# Πίνακας Καιρού" > $DASHBOARD
echo "### Τελευταία Ενημέρωση: $(date)" >> $DASHBOARD
echo "| Τοποθεσία       | Ελάχιστη Θερμοκρασία | Μέγιστη Θερμοκρασία | Τρέχουσα Θερμοκρασία | Περιγραφή Καιρού |" >> $DASHBOARD
echo "|----------------|----------------------|---------------------|---------------------|------------------|" >> $DASHBOARD

# Fetch weather data for each location
for LOCATION in "${LOCATIONS[@]}"; do
  LAT=$(echo "$LOCATION" | cut -d',' -f1)
  LON=$(echo "$LOCATION" | cut -d',' -f2 | cut -d' ' -f1)
  NAME=$(echo "$LOCATION" | cut -d' ' -f2-)

  # Call Open-Meteo API with Greek localization
  WEATHER=$(curl -s "https://api.open-meteo.com/v1/forecast?latitude=$LAT&longitude=$LON&current_weather=true&daily=temperature_2m_min,temperature_2m_max&timezone=auto&lang=el")
  
  if [ $? -eq 0 ]; then
    # Parse data using jq
    TEMP_MIN=$(echo "$WEATHER" | jq '.daily.temperature_2m_min[0]')
    TEMP_MAX=$(echo "$WEATHER" | jq '.daily.temperature_2m_max[0]')
    CURRENT_TEMP=$(echo "$WEATHER" | jq '.current_weather.temperature')
    CURRENT_DESC=$(echo "$WEATHER" | jq -r '.current_weather.weathercode')

    # Add weather data to the dashboard
    echo "| $NAME | ${TEMP_MIN}°C                  | ${TEMP_MAX}°C                | ${CURRENT_TEMP}°C              | ${CURRENT_DESC} |" >> $DASHBOARD
  else
    echo "[$(date)] ERROR: Failed to fetch weather data for $NAME" >> $LOG_FILE
  fi
done

# Log completion
echo "[$(date)] Weather dashboard generated successfully"
