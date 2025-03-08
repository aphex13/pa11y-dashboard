# Force rebuild: 2025-03-08-auth
FROM node:18

# Arbeitsverzeichnis setzen
WORKDIR /app

# Abhängigkeiten installieren
COPY package*.json ./
RUN npm install
COPY . .

# Pa11y Webservice installieren
RUN npm install pa11y-webservice

# Netcat (nc) installieren
#RUN apt-get update && apt-get install -y netcat-openbsd && rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install -y netcat-traditional && rm -rf /var/lib/apt/lists/*

# Warte-Skript für MongoDB erstellen
RUN echo '#!/bin/bash\n\
echo "⏳ Warten auf MongoDB-Verfügbarkeit..."\n\
until nc -z pa11y-pa11y-mongodb-zpdssw 27017; do\n\
    echo "⏳ MongoDB nicht verfügbar, warte..."\n\
    sleep 5\n\
done\n\
echo "✅ MongoDB ist jetzt verfügbar!"\n\
' > /app/wait-for-mongo.sh && chmod +x /app/wait-for-mongo.sh

# Konfigurationsdatei mit der internen MongoDB-URL
RUN mkdir -p config && echo '{\
    "port": 4000,\
    "noindex": false,\
    "readonly": false,\
    "siteMessage": "MongoDB mit Authentifizierung",\
    "webservice": {\
        "database": "mongodb://mongo:PAmongodb11Y@pa11y-pa11y-mongodb-zpdssw:27017/admin",\
        "host": "0.0.0.0",\
        "port": 3000,\
        "cron": "0 30 0 * * *"\
    }\
}' > config/production.json

# Webservice-Konfiguration
RUN mkdir -p node_modules/pa11y-webservice/config && echo '{\
    "port": 3000,\
    "host": "0.0.0.0",\
    "database": "mmongodb://mongo:PAmongodb11Y@pa11y-pa11y-mongodb-zpdssw:27017/admin",\
    "cron": "0 30 0 * * *"\
}' > node_modules/pa11y-webservice/config/production.json

# Start-Skript mit Wartezeit für MongoDB
RUN echo '#!/bin/bash\n\
# MongoDB prüfen\n\
/app/wait-for-mongo.sh\n\
\n\
# Webservice starten\n\
cd /app/node_modules/pa11y-webservice\n\
NODE_ENV=production node index.js &\n\
WEBSERVICE_PID=$!\n\
\n\
# Warten, damit der Webservice hochfährt\n\
sleep 15\n\
\n\
# Pa11y Dashboard starten\n\
cd /app\n\
NODE_ENV=production node index.js\n\
' > /app/start.sh && chmod +x /app/start.sh

# Ports
EXPOSE 4100
EXPOSE 3000

# Gesundheitscheck mit längerer Wartezeit
HEALTHCHECK --interval=30s --timeout=15s --start-period=60s --retries=5 \
  CMD curl -f http://localhost:4000/ || exit 1

# Starten
CMD ["/app/start.sh"]
