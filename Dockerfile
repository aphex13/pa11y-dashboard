# Force rebuild: 2025-03-08-999999
FROM node:18

# Install diagnostic tools
RUN apt-get update && \
    apt-get install -y curl dnsutils iputils-ping net-tools netcat-traditional && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /diagnose

# Create a diagnostic script
RUN echo '#!/bin/bash\n\
echo "=== NETZWERK-DIAGNOSE ===" > /diagnose/results.txt\n\
echo "Hostname: $(hostname)" >> /diagnose/results.txt\n\
echo "Container IP: $(hostname -i)" >> /diagnose/results.txt\n\
echo "" >> /diagnose/results.txt\n\
\n\
echo "=== DNS-AUFLÖSUNG ===" >> /diagnose/results.txt\n\
echo "Versuche pa11y-pa11y-mongodb aufzulösen:" >> /diagnose/results.txt\n\
nslookup pa11y-pa11y-mongodb >> /diagnose/results.txt 2>&1 || echo "DNS-Auflösung fehlgeschlagen" >> /diagnose/results.txt\n\
echo "" >> /diagnose/results.txt\n\
\n\
echo "=== PING-TEST ===" >> /diagnose/results.txt\n\
echo "Pinge pa11y-pa11y-mongodb an:" >> /diagnose/results.txt\n\
ping -c 3 pa11y-pa11y-mongodb >> /diagnose/results.txt 2>&1 || echo "Ping fehlgeschlagen" >> /diagnose/results.txt\n\
echo "" >> /diagnose/results.txt\n\
\n\
echo "=== DOCKER NETZWERK ===" >> /diagnose/results.txt\n\
echo "Netzwerkinterfaces:" >> /diagnose/results.txt\n\
ip addr >> /diagnose/results.txt\n\
echo "" >> /diagnose/results.txt\n\
\n\
echo "Routing-Tabelle:" >> /diagnose/results.txt\n\
ip route >> /diagnose/results.txt\n\
echo "" >> /diagnose/results.txt\n\
\n\
echo "=== MONGODB-VERBINDUNGSTEST ===" >> /diagnose/results.txt\n\
echo "Test der MongoDB-Verbindung auf pa11y-pa11y-mongodb:27017:" >> /diagnose/results.txt\n\
nc -zv pa11y-pa11y-mongodb 27017 >> /diagnose/results.txt 2>&1 || echo "Verbindung fehlgeschlagen" >> /diagnose/results.txt\n\
echo "" >> /diagnose/results.txt\n\
\n\
echo "Test der MongoDB-Verbindung auf 172.17.0.1:27017:" >> /diagnose/results.txt\n\
nc -zv 172.17.0.1 27017 >> /diagnose/results.txt 2>&1 || echo "Verbindung fehlgeschlagen" >> /diagnose/results.txt\n\
echo "" >> /diagnose/results.txt\n\
\n\
echo "Test der MongoDB-Verbindung auf der Docker-Bridge:" >> /diagnose/results.txt\n\
GATEWAY=$(ip route | grep default | awk "{print \$3}")\n\
echo "Gateway: $GATEWAY" >> /diagnose/results.txt\n\
nc -zv $GATEWAY 27017 >> /diagnose/results.txt 2>&1 || echo "Verbindung fehlgeschlagen" >> /diagnose/results.txt\n\
echo "" >> /diagnose/results.txt\n\
\n\
echo "=== DIAGNOSE ABGESCHLOSSEN ===" >> /diagnose/results.txt\n\
cat /diagnose/results.txt\n\
echo "Container bleibt aktiv für weitere Diagnose"\n\
\n\
# Sorge dafür, dass der Container aktiv bleibt\n\
tail -f /dev/null\n\
' > /diagnose/run.sh

RUN chmod +x /diagnose/run.sh

# Keep the container running
CMD ["/diagnose/run.sh"]
