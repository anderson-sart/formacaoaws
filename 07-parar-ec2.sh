#!/bin/bash

# Verifica se o nome da instância foi fornecido
if [ -z "$1" ]; then
    echo "Uso: $0 nome_da_instancia"
    exit 1
fi

INSTANCE_NAME=$1

# Obtém o ID da instância em estado "running" usando o AWS CLI
INSTANCE_ID=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=$INSTANCE_NAME" "Name=instance-state-name" \
    --query "Reservations[].Instances[].InstanceId" \
    --output text)

# Verifica se o ID foi encontrado
if [ -z "$INSTANCE_ID" ]; then
    echo "Nenhuma instância encontrada com o nome: $INSTANCE_NAME"
    exit 1
fi

echo "ID da instância para '$INSTANCE_NAME': $INSTANCE_ID"

# Obter o status da instância
STATUS=$(aws ec2 describe-instance-status --instance-id $INSTANCE_ID --query "InstanceStatuses[0].InstanceState.Name" --output text)

echo "Status atual da instância $INSTANCE_ID: $STATUS"

# Verificar se a instância está rodando
if [ "$STATUS" == "running" ]; then
    echo "A instância está em execução. Tentando parar..."
    aws ec2 stop-instances --instance-ids $INSTANCE_ID
    echo "Comando de parada enviado para a instância $INSTANCE_ID."
elif [ "$STATUS" == "stopped" ]; then
    echo "A instância já está parada."
else
    echo "Status da instância é '$STATUS'. Não é possível parar."
fi