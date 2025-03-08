# Basis-Image mit Node.js 18
FROM node:18

# Arbeitsverzeichnis setzen
WORKDIR /app

# Abhängigkeiten installieren
COPY package.json package-lock.json ./
RUN npm install

# Kopiere restlichen Code
COPY . .

# Standardport für das Dashboard
ENV PORT=4000
# Setze MongoDB URI für externen Service anstatt lokale Installation
ENV MONGO_URL=mongodb://mongodb:27017/pa11y
EXPOSE 4000

# Starte nur die Node.js Anwendung
CMD ["npm", "start"]
