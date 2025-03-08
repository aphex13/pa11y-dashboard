# Force rebuild: 2025-03-08-999999
# Basis-Image mit Node.js 18
FROM node:18

# Installiere Curl für Healthcheck und andere Dienstprogramme
RUN apt-get update && \
    apt-get install -y curl dnsutils iputils-ping net-tools && \
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

# Konfigurationsdatei mit direkter MongoDB-IP erstellen - hier wird die Container-IP verwendet
RUN mkdir -p config && echo '{\
    "port": 4000,\
    "noindex": false,\
    "readonly": false,\
    "siteMessage": "",\
    "webservice": {\
        "database": "mongodb://172.17.0.1:27017/pa11y-webservice",\
        "host": "0.0.0.0",\
        "port": 3000,\
        "cron": "0 30 0 * * *"\
    }\
}' > config/production.json

# Erstelle auch eine Konfiguration für den Webservice
RUN mkdir -p node_modules/pa11y-webservice/config && echo '{\
    "port": 3000,\
    "host": "0.0.0.0",\
    "database": "mongodb://172.17.0.1:27017/pa11y-webservice",\
    "cron": "0 30 0 * * *"\
}' > node_modules/pa11y-webservice/config/production.json

# Erstelle ein Diagnoseskript
RUN echo '#!/bin/bash\n\
echo "---- DNS-Test ----"\n\
nslookup pa11y-pa11y-mongodb || echo "DNS-Auflösung fehlgeschlagen"\n\
echo "---- Ping-Test ----"\n\
ping -c 2 pa11y-pa11y-mongodb || echo "Ping fehlgeschlagen"\n\
echo "---- Netzwerk-Interfaces ----"\n\
ip addr\n\
echo "---- Route ----"\n\
ip route\n\
echo "---- Aktive Verbindungen ----"\n\
netstat -tuln\n\
' > /app/diagnose.sh && chmod +x /app/diagnose.sh

# Erstelle ein verbessertes Startscript
RUN echo '#!/bin/bash\n\
echo "Starte Diagnose..."\n\
/app/diagnose.sh\n\
\n\
echo "Verbindung zur MongoDB testen..."\n\
# Prüfe, ob die MongoDB direkt erreichbar ist\n\
if nc -z 172.17.0.1 27017; then\n\
  echo "MongoDB auf 172.17.0.1:27017 ist erreichbar"\n\
else\n\
  echo "MongoDB auf 172.17.0.1:27017 ist NICHT erreichbar"\n\
  echo "Versuche alternative Konfiguration..."\n\
  # Ermittle die Docker-Bridge-Gateway-IP\n\
  GATEWAY=$(ip route | grep default | awk "{print \$3}")\n\
  echo "Docker Gateway: $GATEWAY"\n\
  # Aktualisiere die Konfigurationsdateien mit der Gateway-IP\n\
  sed -i "s|172.17.0.1|$GATEWAY|g" /app/config/production.json\n\
  sed -i "s|172.17.0.1|$GATEWAY|g" /app/node_modules/pa11y-webservice/config/production.json\n\
fi\n\
\n\
echo "Starte Pa11y Webservice..."\n\
cd /app/node_modules/pa11y-webservice\n\
NODE_ENV=production node index.js &\n\
WEBSERVICE_PID=$!\n\
\n\
echo "Warte, bis der Webservice gestartet ist..."\n\
sleep 10\n\
\n\
echo "Prüfe, ob Webservice läuft..."\n\
if ps -p $WEBSERVICE_PID > /dev/null; then\n\
  echo "Webservice läuft mit PID $WEBSERVICE_PID"\n\
else\n\
  echo "Webservice konnte nicht gestartet werden!"\n\
  exit 1\n\
fi\n\
\n\
echo "Starte Pa11y Dashboard..."\n\
cd /app\n\
NODE_ENV=production node index.js\n\
' > /app/start.sh && chmod +x /app/start.sh

# Setze Environment-Variablen
ENV NODE_ENV=production
ENV PORT=4000
ENV HOST=0.0.0.0

# Expose beide Ports
EXPOSE 4000
EXPOSE 3000

# Health Check mit längerer Startzeit und robusterem Test
HEALTHCHECK --interval=30s --timeout=15s --start-period=60s --retries=5 \
  CMD curl -f http://localhost:4000/ || exit 1

# Starte beide Dienste
CMD ["/app/start.sh"]
