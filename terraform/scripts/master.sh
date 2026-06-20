#!/bin/bash
set -e
# Instala o K3s e marca esta maquina como 'infra' (onde o banco vai morar)
curl -sfL https://get.k3s.io | sh -s - server --node-label role=infra
 
# Guarda o IP e o token no SSM para os workers entrarem sozinhos
TOKEN=$(cat /var/lib/rancher/k3s/server/node-token)
IP=$(hostname -I | awk '{print $1}')
aws ssm put-parameter --name /taskflow/master-ip --type String --value "$IP" --overwrite --region us-east-1
aws ssm put-parameter --name /taskflow/k3s-token --type SecureString --value "$TOKEN" --overwrite --region us-east-1
 
# Cria o espaco do app
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
kubectl create namespace taskflow || true
