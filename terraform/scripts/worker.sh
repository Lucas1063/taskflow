#!/bin/bash
set -e

while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
  echo "Aguardando lock do apt liberar..."
  sleep 5
done

apt-get update -y && apt-get install -y awscli

if ! command -v aws >/dev/null 2>&1; then
  echo "ERRO FATAL: aws cli não foi instalado corretamente." >&2
  exit 1
fi

MASTER_IP=""
TOKEN=""
for i in $(seq 1 20); do
  MASTER_IP=$(aws ssm get-parameter --name /taskflow/master-ip --query Parameter.Value --output text --region us-east-1 2>/dev/null || true)
  TOKEN=$(aws ssm get-parameter --name /taskflow/k3s-token --with-decryption --query Parameter.Value --output text --region us-east-1 2>/dev/null || true)
  if [ -n "$MASTER_IP" ] && [ -n "$TOKEN" ]; then
    echo "Parametros encontrados: MASTER_IP=$MASTER_IP"
    break
  fi
  echo "Tentativa $i/20: SSM ainda sem parametros, aguardando 15s..."
  sleep 15
done

if [ -z "$MASTER_IP" ] || [ -z "$TOKEN" ]; then
  echo "ERRO FATAL: não consegui obter MASTER_IP/TOKEN do SSM depois de 20 tentativas." >&2
  exit 1
fi

curl -sfL https://get.k3s.io | K3S_URL="https://$MASTER_IP:6443" K3S_TOKEN="$TOKEN" sh -s - agent

echo "Entrei no cluster do master $MASTER_IP"