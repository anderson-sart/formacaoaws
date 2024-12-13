#!/bin/bash

# Verifica se o nome da instância foi fornecido
if [ -z "$1" ]; then
    echo "Uso: $0 nome_da_instancia"
    exit 1
fi

INSTANCE_NAME=$1

# Obtém o ID da instância usando o AWS CLI
INSTANCE_ID=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=$INSTANCE_NAME" "Name=instance-state-name,Values=stopped" \
    --query "Reservations[].Instances[].InstanceId" \
    --output text)

# Verifica se o ID foi encontrado
if [ -z "$INSTANCE_ID" ]; then
    echo "Nenhuma instância parada encontrada com o nome: $INSTANCE_NAME"
    exit 1
fi

echo "ID da instância para '$INSTANCE_NAME': $INSTANCE_ID"

# Obter o status da instância
STATUS=$(aws ec2 describe-instance-status --instance-id $INSTANCE_ID --query "InstanceStatuses[0].InstanceState.Name" --output text)

if [ "$STATUS" != "running" ]; then
    echo "A instância está parada. Iniciando..."
    
    # Iniciar a instância
    aws ec2 start-instances --instance-ids $INSTANCE_ID
    echo "Iniciando a instância $INSTANCE_ID. Aguardando até estar em execução..."
    
    # Esperar até que a instância esteja completamente em execução
    aws ec2 wait instance-running --instance-ids $INSTANCE_ID
    echo "Instância $INSTANCE_ID iniciada com sucesso e está em execução."
else
    echo "A instância não está parada. Status atual: $STATUS"
    echo "Nada a ser feito."
fi
