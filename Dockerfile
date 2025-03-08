# Basis-Image mit Node.js 16
FROM node:16

# Installiere notwendige Pakete für MongoDB
RUN apt-get update && apt-get install -y gnupg wget

# Füge den MongoDB GPG-Schlüssel hinzu
RUN wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | apt-key add -

# Füge das offizielle MongoDB-Repository hinzu
RUN echo "deb http://repo.mongodb.org/apt/debian buster/mongodb-org/4.4 main" | tee /etc/apt/sources.list.d/mongodb-org-4.4.list

# Aktualisiere die Paketliste und installiere MongoDB
RUN apt-get update && apt-get install -y mongodb-org

# Erstelle das MongoDB-Datenverzeichnis
RUN mkdir -p /data/db

# Setze das Arbeitsverzeichnis
WORKDIR /app

# Kopiere die Dateien und installiere Abhängigkeiten
COPY package.json package-lock.json ./
RUN npm install

# Kopiere den restlichen Code
COPY . .

# Standardport für das Dashboard setzen
ENV PORT=4000
ENV MONGO_URL=mongodb://localhost:27017/pa11y
EXPOSE 4000

# Starte MongoDB und die Anwendung
CMD mongod --fork --logpath /var/log/mongodb.log && npm start
