# Force rebuild: 2025-03-08-987654
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

# Wichtig: Konfiguriere sowohl den Webservice als auch das Dashboard
# so, dass sie die externe MongoDB verwenden
RUN mkdir -p config && echo '{\
    "port": 4000,\
    "noindex": false,\
    "readonly": false,\
    "siteMessage": "",\
    "webservice": {\
        "database": "mongodb://pa11y-pa11y-mongodb:27017/pa11y-webservice",\
        "host": "localhost",\
        "port": 3000,\
        "cron": "0 30 0 * * *"\
    }\
}' > config/production.json

# Installiere pa11y-webservice lokal
RUN npm install pa11y-webservice

# Erstelle ein Startscript, das beide Dienste startet
RUN echo '#!/bin/bash\n\
# Starte den Pa11y Webservice\n\
cd /app/node_modules/pa11y-webservice\n\
NODE_ENV=production node index.js &\n\
# Warte, bis der Webservice gestartet ist\n\
sleep 5\n\
# Starte das Pa11y Dashboard\n\
cd /app\n\
NODE_ENV=production node index.js\n\
' > /app/start.sh && chmod +x /app/start.sh

# Setze Environment-Variablen
ENV NODE_ENV=production
ENV PORT=4000
ENV PA11Y_WEBSERVICE_DATABASE=mongodb://pa11y-pa11y-mongodb:27017/pa11y-webservice

# Expose Port für Pa11y Dashboard
EXPOSE 4000
EXPOSE 3000

# Health Check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:4000/ || exit 1

# Starte beide Dienste über das Startscript
CMD ["/app/start.sh"]
