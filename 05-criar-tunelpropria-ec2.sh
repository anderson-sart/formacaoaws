#!/bin/bash

# Verifica se o nome da instância foi fornecido
if [ -z "$1" ]; then
    echo "Uso: $0 nome_da_instancia"
    exit 1
fi

INSTANCE_NAME=$1

# Obtém o ID da instância em estado "running" usando o AWS CLI
INSTANCE_ID=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=$INSTANCE_NAME" "Name=instance-state-name,Values=running" \
    --query "Reservations[].Instances[].InstanceId" \
    --output text)

# Verifica se o ID foi encontrado
if [ -z "$INSTANCE_ID" ]; then
    echo "Nenhuma instância encontrada com o nome: $INSTANCE_NAME"
    exit 1
fi

echo "ID da instância para '$INSTANCE_NAME': $INSTANCE_ID"

aws ssm start-session \
    --target $INSTANCE_ID \
    --document-name AWS-StartPortForwardingSessionToRemoteHost \
    --parameters '{"portNumber":["80"],"localPortNumber":["3002"]}'