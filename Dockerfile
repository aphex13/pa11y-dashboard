# Basis-Image mit Node.js 18
FROM node:18

# Installiere notwendige Pakete für MongoDB
RUN apt-get update && apt-get install -y gnupg curl

# Füge den MongoDB GPG-Schlüssel korrekt hinzu
RUN curl -fsSL https://pgp.mongodb.com/server-6.0.asc | \
    gpg --dearmor -o /usr/share/keyrings/mongodb-server-6.0.gpg

# Füge das richtige MongoDB-Repository für Debian Bookworm hinzu
RUN echo "deb [signed-by=/usr/share/keyrings/mongodb-server-6.0.gpg] https://repo.mongodb.org/apt/debian bookworm/mongodb-org/6.0 main" | \
    tee /etc/apt/sources.list.d/mongodb-org-6.0.list

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

# MongoDB & Node.js starten (mit JSON-Format für CMD wie in der Warnung empfohlen)
CMD ["sh", "-c", "mongod --fork --logpath /var/log/mongodb.log && npm start"]
