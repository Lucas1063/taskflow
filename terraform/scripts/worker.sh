#!/bin/bash
set -e
apt-get update -y && apt-get install -y awscli
 
# Espera o master publicar o IP e o token no SSM (tenta ate 20 vezes)
for i in $(seq 1 20); do
  MASTER_IP=$(aws ssm get-parameter --name /taskflow/master-ip --query Parameter.Value --output text --region us-east-1 2>/dev/null || true)
  TOKEN=$(aws ssm get-parameter --name /taskflow/k3s-token --with-decryption --query Parameter.Value --output text --region us-east-1 2>/dev/null || true)
  if [ -n "$MASTER_IP" ] && [ -n "$TOKEN" ]; then break; fi
  sleep 15
done
 
# Entra no cluster sozinha
curl -sfL https://get.k3s.io | K3S_URL="https://$MASTER_IP:6443" K3S_TOKEN="$TOKEN" sh -s - agent
echo "Entrei no cluster do master $MASTER_IP"
