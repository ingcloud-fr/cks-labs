#!/bin/bash
set -e

echo "🔧 Generating TLS certs for Docker..."

CERTS_DIR="/opt/docker-certs"
sudo mkdir -p $CERTS_DIR


# Génération des certificats si absents
if [ ! -f $CERTS_DIR/ca.pem ] || [ ! -f $CERTS_DIRcert.pem ] || [ ! -f $CERTS_DIRkey.pem ]; then
  # 1. CA
  sudo openssl genrsa -out $CERTS_DIR/ca-key.pem 4096
  sudo openssl req -new -x509 -days 365 -key $CERTS_DIR/ca-key.pem -sha256 -subj "/CN=docker-ca" -out $CERTS_DIR/ca.pem

  # 2. Server key
  sudo openssl genrsa -out $CERTS_DIR/key.pem 4096
  sudo openssl req -subj "/CN=controlplane01" -new -key $CERTS_DIR/key.pem -out $CERTS_DIR/server.csr

  # 3. Extensions
  cat <<EOF | sudo tee $CERTS_DIR/extfile.cnf > /dev/null
subjectAltName = IP:127.0.0.1,IP:0.0.0.0,DNS:localhost
extendedKeyUsage = serverAuth
EOF

  # 4. Certificat serveur signé
  sudo openssl x509 -req -days 365 -sha256 -in $CERTS_DIR/server.csr -CA $CERTS_DIR/ca.pem -CAkey $CERTS_DIR/ca-key.pem \
    -CAcreateserial -out $CERTS_DIR/cert.pem -extfile $CERTS_DIR/extfile.cnf

  sudo rm -f $CERTS_DIR/server.csr $CERTS_DIR/extfile.cnf ca.srl
  sudo chmod 0400 $CERTS_DIR/key.pem $CERTS_DIR/ca-key.pem
  sudo chmod 0444 $CERTS_DIR/ca.pem $CERTS_DIR/cert.pem
fi

echo "⚙️  Configuring Docker daemon ..."

# Backup config existante
sudo cp /lib/systemd/system/docker.service /lib/systemd/system/docker.service.bak

# On modifie /lib/systemd/system/docker.service (suppression de -H fd://)
sudo sed -i 's|-H fd://||' /lib/systemd/system/docker.service

# Copier les certs
sudo mkdir -p /etc/docker/certs
sudo cp $CERTS_DIR/* /etc/docker/certs/

# # Configuration sécurisée
# cat <<EOF | sudo tee /etc/docker/daemon.json > /dev/null
# {
#   "hosts": ["unix:///var/run/docker.sock", "tcp://0.0.0.0:2376"],
#   "tls": true,
#   "tlsverify": true,
#   "tlscacert": "/etc/docker/certs/ca.pem",
#   "tlscert": "/etc/docker/certs/cert.pem",
#   "tlskey": "/etc/docker/certs/key.pem"
# }
# EOF

# Exposition dangereuse : port 2375 sans TLS
sudo cp tools/daemon.json /etc/docker/daemon.json

# Redémarrage de Docker
sudo systemctl daemon-reexec
sudo systemctl restart docker

echo
echo "************************************"
echo
cat README.txt
echo
