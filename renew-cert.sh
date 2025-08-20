#!/bin/bash
set -e

# Caminho base do projeto
BASE_DIR="/home/ubuntu/scalelite-run-redis-2"
LOG_FILE="$BASE_DIR/renew-cert.log"

echo "===== $(date) =====" >> "$LOG_FILE"
echo "Iniciando renovação do certificado Scalelite..." >> "$LOG_FILE"

cd "$BASE_DIR"

# Parar containers
echo "Parando containers..." >> "$LOG_FILE"
sudo docker-compose down >> "$LOG_FILE" 2>&1

# Remover certificados antigos
echo "Removendo certificados antigos..." >> "$LOG_FILE"
sudo rm -rf ./data/certbot/conf/live/scalelite.avaedus.com.br >> "$LOG_FILE" 2>&1
sudo rm -rf ./data/certbot/conf/archive/scalelite.avaedus.com.br >> "$LOG_FILE" 2>&1
sudo rm -rf ./data/certbot/conf/renewal/scalelite.avaedus.com.br.conf >> "$LOG_FILE" 2>&1

# Rodar init-letsencrypt.sh de forma não interativa
echo "Rodando init-letsencrypt.sh..." >> "$LOG_FILE"
yes | sudo ./init-letsencrypt.sh >> "$LOG_FILE" 2>&1

# Subir containers novamente
echo "Subindo containers..." >> "$LOG_FILE"
sudo docker-compose up -d >> "$LOG_FILE" 2>&1

echo "Renovação finalizada com sucesso." >> "$LOG_FILE"
echo "" >> "$LOG_FILE"
