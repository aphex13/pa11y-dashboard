# Use Node.js as base image
FROM node:18

# Install MongoDB from Debian repositories (simpler approach)
RUN apt-get update && \
    apt-get install -y mongodb && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create MongoDB data directory
RUN mkdir -p /data/db

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy application code
COPY . .

# Create a specific config for production
RUN mkdir -p config && echo '{\
    "port": 4000,\
    "noindex": false,\
    "readonly": false,\
    "siteMessage": "",\
    "webservice": {\
        "database": "mongodb://Default mongo:PAmongoDB11Y@pa11y-pa11y-mongodb:27017/pa11y-webservice",\
        "host": "0.0.0.0",\
        "port": 3000,\
        "cron": "0 30 0 * * *"\
    }\
}' > config/production.json

# Create startup script
RUN echo '#!/bin/bash\n\
# Start MongoDB\n\
mkdir -p /data/db\n\
mongod --fork --logpath /var/log/mongodb.log\n\
# Wait for MongoDB to start\n\
sleep 5\n\
# Start Pa11y Dashboard\n\
NODE_ENV=production npm start\n\
' > /app/start.sh && chmod +x /app/start.sh

# Expose Pa11y Dashboard port
EXPOSE 4000

# Run startup script
CMD ["/app/start.sh"]
