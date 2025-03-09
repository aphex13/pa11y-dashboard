# Basis-Image mit Node.js
FROM node:16

# Arbeitsverzeichnis setzen
WORKDIR /app

RUN apt-get update && apt-get install -y libnss3

# Abhängigkeiten installieren
COPY package*.json ./
RUN npm install

# Quelldateien kopieren
COPY . .

# Port freigeben (Standardport ist 4000)
EXPOSE 4100

# Startbefehl
CMD ["npm", "start"]
