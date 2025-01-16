#!/bin/bash

ECR_REGISTRY="140023361867.dkr.ecr.us-east-1.amazonaws.com"
REGION="us-east-1"

# Autenticar no ECR usando AWS CLI
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_REGISTRY

# Criar o builder Buildx (se ainda não existir)
docker buildx create --name mybuilder --use --bootstrap || true

# Build usando Buildx (com suporte a multi-platform e cache melhorado)
docker buildx build --platform linux/amd64 -t bia --load .

# Tag da imagem corretamente
docker tag bia:latest $ECR_REGISTRY/bia:latest

# Push da imagem para o ECR
docker push $ECR_REGISTRY/bia:latest