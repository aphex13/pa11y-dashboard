# Force rebuild: 2025-03-08-embedded
FROM node:18

# Installation von MongoDB und anderen notwendigen Paketen
RUN apt-get update && \
    apt-get install -y wget gnupg curl && \
    wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | apt-key add - && \
    echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/4.4 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-4.4.list && \
    apt-get update && \
    apt-get install -y mongodb-org && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Erstelle MongoDB-Datenverzeichnis
RUN mkdir -p /data/db

# Arbeitsverzeichnis setzen
WORKDIR /app

# Abhängigkeiten installieren
COPY package*.json ./
RUN npm install
COPY . .

# Pa11y Webservice installieren
RUN npm install pa11y-webservice

# Konfigurationsdatei mit lokaler MongoDB
RUN mkdir -p config && echo '{\
    "port": 4000,\
    "noindex": false,\
    "readonly": false,\
    "siteMessage": "Integrierte MongoDB-Instanz",\
    "webservice": {\
        "database": "mongodb://localhost:27017/pa11y-webservice",\
        "host": "0.0.0.0",\
        "port": 3000,\
        "cron": "0 30 0 * * *"\
    }\
}' > config/production.json

# Webservice-Konfiguration
RUN mkdir -p node_modules/pa11y-webservice/config && echo '{\
    "port": 3000,\
    "host": "0.0.0.0",\
    "database": "mongodb://localhost:27017/pa11y-webservice",\
    "cron": "0 30 0 * * *"\
}' > node_modules/pa11y-webservice/config/production.json

# Startscript das MongoDB, Webservice und Dashboard startet
RUN echo '#!/bin/bash\n\
# MongoDB starten\n\
echo "MongoDB starten..."\n\
mkdir -p /data/db\n\
mongod --bind_ip_all --fork --logpath /var/log/mongodb.log\n\
\n\
# Kurz warten und prüfen, ob MongoDB läuft\n\
sleep 5\n\
echo "MongoDB-Status:"\n\
ps aux | grep mongod\n\
\n\
# Webservice starten\n\
echo "Pa11y Webservice starten..."\n\
cd /app/node_modules/pa11y-webservice\n\
NODE_ENV=production node index.js &\n\
WEBSERVICE_PID=$!\n\
\n\
# Warten, bis der Webservice läuft\n\
sleep 15\n\
echo "Webservice-Status: PID $WEBSERVICE_PID"\n\
\n\
# Pa11y Dashboard starten\n\
echo "Pa11y Dashboard starten..."\n\
cd /app\n\
NODE_ENV=production node index.js\n\
' > /app/start.sh && chmod +x /app/start.sh

# Ports
EXPOSE 4000
EXPOSE 3000
EXPOSE 27017

# Gesundheitscheck mit längerer Wartezeit
HEALTHCHECK --interval=30s --timeout=15s --start-period=120s --retries=5 \
  CMD curl -f http://localhost:4000/ || exit 1

# Starten
CMD ["/app/start.sh"]
