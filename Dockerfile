# Node.js Basis-Image verwenden
FROM node:16

# MongoDB installieren
RUN apt-get update && apt-get install -y mongodb

# Arbeitsverzeichnis setzen
WORKDIR /app

# Abhängigkeiten installieren
COPY package.json package-lock.json ./
RUN npm install

# Anwendungscode kopieren
COPY . .

# Standardport für das Dashboard
ENV PORT=4000
ENV MONGO_URL=mongodb://localhost:27017/pa11y
EXPOSE 4000

# MongoDB starten und dann die Anwendung starten
CMD mongod --fork --logpath /var/log/mongodb.log && npm start
