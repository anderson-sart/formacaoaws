#!/bin/bash

# Verifica se o nome da instância foi fornecido
if [ -z "$1" ]; then
    echo "Uso: $0 nome_da_instancia nome_do_rds"
    exit 1
fi

# Verifica se o nome do RDS foi fornecido
if [ -z "$2" ]; then
    echo "Uso: $0 nome_da_instancia nome_do_rds"
    exit 1
fi

INSTANCE_NAME=$1
RDS_NAME=$2

# Obtém o ID da instância em estado "running" usando o AWS CLI
INSTANCE_ID=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=$INSTANCE_NAME" "Name=instance-state-name,Values=running" \
    --query "Reservations[].Instances[].InstanceId" \
    --output text)

# Verifica se o ID foi encontrado
if [ -z "$INSTANCE_ID" ]; then
    echo "Nenhuma instância EC2 'running' encontrada com o nome: $INSTANCE_NAME"
    exit 1
fi

echo "ID da instância EC2 para '$INSTANCE_NAME': $INSTANCE_ID"

# Obtém o endpoint do RDS usando o AWS CLI
ENDPOINT=$(aws rds describe-db-instances \
    --query "DBInstances[?DBInstanceIdentifier=='$RDS_NAME'].Endpoint.Address" \
    --output text)

# Verifica se o endpoint foi encontrado
if [ -z "$ENDPOINT" ]; then
    echo "Nenhuma instância RDS encontrada com o nome: $RDS_NAME"
    exit 1
fi

echo "Endpoint do RDS para '$RDS_NAME': $ENDPOINT"

# Inicia uma sessão SSM para criar um túnel de redirecionamento para o RDS
echo "Iniciando sessão SSM para redirecionar porta local (5433) para o RDS (5432)..."
aws ssm start-session \
    --target $INSTANCE_ID \
    --document-name AWS-StartPortForwardingSessionToRemoteHost \
    --parameters "{\"host\":[\"$ENDPOINT\"],\"portNumber\":[\"5432\"],\"localPortNumber\":[\"5433\"]}"

if [ $? -eq 0 ]; then
    echo "Túnel SSM configurado com sucesso!"
    echo "Agora você pode acessar o RDS '$RDS_NAME' em localhost:5433"
else
    echo "Falha ao iniciar a sessão SSM."
    exit 1
fi
