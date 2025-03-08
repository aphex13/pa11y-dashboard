# Force rebuild: 2025-03-08-543210
# Basis-Image mit Node.js 18
FROM node:18

# Installiere Curl für Healthcheck
RUN apt-get update && \
    apt-get install -y curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Arbeitsverzeichnis setzen
WORKDIR /app

# Kopiere package files
COPY package*.json ./

# Installiere Abhängigkeiten
RUN npm install

# Kopiere restlichen Code
COPY . .

# Pa11y Webservice als Abhängigkeit installieren
RUN npm install pa11y-webservice

# Konfigurationsdatei mit explizitem Host-Binding erstellen
RUN mkdir -p config && echo '{\
    "port": 4000,\
    "noindex": false,\
    "readonly": false,\
    "siteMessage": "",\
    "webservice": {\
        "database": "mongodb://pa11y-pa11y-mongodb:27017/pa11y-webservice",\
        "host": "0.0.0.0",\
        "port": 3000,\
        "cron": "0 30 0 * * *"\
    }\
}' > config/production.json

# Erstelle auch eine Konfiguration für den Webservice
RUN mkdir -p node_modules/pa11y-webservice/config && echo '{\
    "port": 3000,\
    "host": "0.0.0.0",\
    "database": "mongodb://pa11y-pa11y-mongodb:27017/pa11y-webservice",\
    "cron": "0 30 0 * * *"\
}' > node_modules/pa11y-webservice/config/production.json

# Startscript erstellen, das dem Dashboard explizit den Host 0.0.0.0 zuweist
RUN echo '#!/bin/bash\n\
# Starte Pa11y Webservice im Hintergrund\n\
cd /app/node_modules/pa11y-webservice\n\
NODE_ENV=production node index.js &\n\
# Warte, bis der Webservice gestartet ist\n\
sleep 10\n\
# Starte das Dashboard\n\
cd /app\n\
# Explizit auf allen Interfaces binden\n\
NODE_ENV=production node index.js\n\
' > /app/start.sh && chmod +x /app/start.sh

# Setze Environment-Variablen
ENV NODE_ENV=production
ENV PORT=4000
ENV HOST=0.0.0.0

# Expose beide Ports
EXPOSE 4000
EXPOSE 3000

# Health Check mit längerer Startzeit
HEALTHCHECK --interval=30s --timeout=15s --start-period=60s --retries=5 \
  CMD curl -f http://localhost:4000/ || exit 1

# Starte beide Dienste
CMD ["/app/start.sh"]
