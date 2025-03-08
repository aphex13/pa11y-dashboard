# Force rebuild: 2025-03-08-123456
FROM node:18

# Arbeitsverzeichnis setzen
WORKDIR /app

# Abhängigkeiten installieren
COPY package*.json ./
RUN npm install
COPY . .

# Konfiguration für Pa11y Dashboard
RUN mkdir -p config && echo '{\
    "port": 4000,\
    "noindex": false,\
    "readonly": false,\
    "siteMessage": "Verbindung zur Datenbank: mongodb://pa11y-pa11y-mongodb:27017/pa11y-webservice",\
    "webservice": {\
        "database": "mongodb://pa11y-pa11y-mongodb:27017/pa11y-webservice",\
        "host": "0.0.0.0",\
        "port": 3000,\
        "cron": "0 30 0 * * *"\
    }\
}' > config/production.json

# Ports freigeben
EXPOSE 4000

# Container dauerhaft laufen lassen, auch wenn der Start fehlschlägt
CMD echo "Starte Pa11y Dashboard..." && \
    echo "Container läuft - verwende 'docker exec' um interaktiv zu arbeiten" && \
    node index.js || \
    echo "Fehler beim Starten von Pa11y Dashboard - Container bleibt für Diagnose aktiv" && \
    tail -f /dev/null
