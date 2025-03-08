# Basis-Image mit Node.js 18 (anstatt 16)
FROM node:18

# MongoDB installieren
RUN apt-get update && apt-get install -y gnupg wget

# MongoDB GPG-Schlüssel hinzufügen
RUN wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | apt-key add -

# MongoDB-Repository hinzufügen
RUN echo "deb http://repo.mongodb.org/apt/debian buster/mongodb-org/4.4 main" | tee /etc/apt/sources.list.d/mongodb-org-4.4.list

# Paketliste aktualisieren und MongoDB installieren
RUN apt-get update && apt-get install -y mongodb-org

# Erstelle das MongoDB-Datenverzeichnis
RUN mkdir -p /data/db

# Arbeitsverzeichnis setzen
WORKDIR /app

# Abhängigkeiten installieren
COPY package.json package-lock.json ./
RUN npm install

# Kopiere restlichen Code
COPY . .

# Standardport für das Dashboard
ENV PORT=4000
ENV MONGO_URL=mongodb://localhost:27017/pa11y
EXPOSE 4000

# MongoDB & Node.js starten
CMD mongod --fork --logpath /var/log/mongodb.log && npm start
