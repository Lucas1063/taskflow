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

curl -sfL https://get.k3s.io | sh -s - server --node-label role=infra

for i in $(seq 1 20); do
  if [ -f /var/lib/rancher/k3s/server/node-token ]; then
    break
  fi
  echo "Aguardando node-token do k3s..."
  sleep 5
done

if [ ! -f /var/lib/rancher/k3s/server/node-token ]; then
  echo "ERRO FATAL: node-token nunca foi criado, k3s server não iniciou." >&2
  exit 1
fi

TOKEN=$(cat /var/lib/rancher/k3s/server/node-token)
IP=$(hostname -I | awk '{print $1}')

aws ssm put-parameter --name /taskflow/master-ip --type String --value "$IP" --overwrite --region us-east-1
aws ssm put-parameter --name /taskflow/k3s-token --type SecureString --value "$TOKEN" --overwrite --region us-east-1

echo "Parametros publicados no SSM: IP=$IP"

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
kubectl create namespace taskflow || true

echo "master.sh finalizado com sucesso."