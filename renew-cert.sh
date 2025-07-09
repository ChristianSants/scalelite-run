#!/bin/bash

set -e  # para o script se algum comando falhar

echo "Parando containers..."
docker-compose down

echo "Removendo certificados antigos..."
rm -rf ./data/certbot/conf/live/scalelite.avaedus.com.br
rm -rf ./data/certbot/conf/archive/scalelite.avaedus.com.br
rm -rf ./data/certbot/conf/renewal/scalelite.avaedus.com.br.conf

echo "Rodando init-letsencrypt.sh..."
./init-letsencrypt.sh >> /var/log/renew-cert.log 2>&1

echo "Subindo containers..."
docker-compose up -d

echo "Renovação finalizada."
