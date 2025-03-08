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

# Konfigurationsdatei mit MongoDB-Authentifizierung
RUN mkdir -p config && echo '{\
    "port": 4000,\
    "noindex": false,\
    "readonly": false,\
    "siteMessage": "MongoDB mit Authentifizierung",\
    "webservice": {\
        "database": "mongodb://mongo:PAmongodb11Y@10.0.1.207:27017/pa11y-webservice?authSource=admin",\
        "host": "0.0.0.0",\
        "port": 3000,\
        "cron": "0 30 0 * * *"\
    }\
}' > config/production.json

# Webservice-Konfiguration
RUN mkdir -p node_modules/pa11y-webservice/config && echo '{\
    "port": 3000,\
    "host": "0.0.0.0",\
    "database": "mongodb://mongo:PAmongodb11Y@10.0.1.207:27017/pa11y-webservice?authSource=admin",\
    "cron": "0 30 0 * * *"\
}' > node_modules/pa11y-webservice/config/production.json

# Startscript
RUN echo '#!/bin/bash\n\
# Webservice starten\n\
cd /app/node_modules/pa11y-webservice\n\
NODE_ENV=production node index.js &\n\
WEBSERVICE_PID=$!\n\
\n\
# Genug Zeit geben, um zu starten\n\
sleep 15\n\
\n\
# Pa11y Dashboard starten\n\
cd /app\n\
NODE_ENV=production node index.js\n\
' > /app/start.sh && chmod +x /app/start.sh

# Ports
EXPOSE 4000
EXPOSE 3000

# Gesundheitscheck mit längerer Wartezeit
HEALTHCHECK --interval=30s --timeout=15s --start-period=60s --retries=5 \
  CMD curl -f http://localhost:4000/ || exit 1

# Starten
CMD ["/app/start.sh"]
