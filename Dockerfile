# Basis-Image mit Node.js 18
FROM node:18

# Arbeitsverzeichnis setzen
WORKDIR /app

# Abhängigkeiten installieren
COPY package.json package-lock.json ./
RUN npm install

# Kopiere restlichen Code
COPY . .

# Konfigurationsdatei erstellen
RUN echo '{\n\
  "port": 4000,\n\
  "noindex": true,\n\
  "readonly": false,\n\
  "siteMessage": "",\n\
  "webservice": {\n\
    "database": "mongodb://mongodb:27017/pa11y-webservice",\n\
    "host": "0.0.0.0",\n\
    "port": 3000,\n\
    "cron": "0 30 0 * * *"\n\
  }\n\
}' > config/production.json

# Standardport für das Dashboard
ENV PORT=4000
ENV NODE_ENV=production
EXPOSE 4000

# Healthcheck hinzufügen
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:4000/ || exit 1

# Starte die Node.js Anwendung
CMD ["npm", "start"]
