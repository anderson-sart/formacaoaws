#!/bin/bash

# Obter o ID da VPC padrão
vpc_id=$(aws ec2 describe-vpcs --filters Name=isDefault,Values=true --query "Vpcs[0].VpcId" --output text)

if [ -z "$vpc_id" ] || [ "$vpc_id" == "None" ]; then
    echo ">[ERRO] Nenhuma VPC padrão encontrada."
    exit 1
else
    echo "> VPC padrão encontrada: $vpc_id"
fi

# Obter o ID da Subnet na zona us-east-1b
subnet_id=$(aws ec2 describe-subnets --filters Name=vpc-id,Values=$vpc_id Name=availabilityZone,Values=us-east-1b --query "Subnets[0].SubnetId" --output text)

if [ -z "$subnet_id" ] || [ "$subnet_id" == "None" ]; then
    echo ">[ERRO] Nenhuma Subnet encontrada na zona us-east-1b para a VPC $vpc_id"
    exit 1
else
    echo "> Subnet encontrada: $subnet_id"
fi

# Obter o Image ID mais recente do Amazon Linux 2023
image_id=$(aws ec2 describe-images \
    --filters "Name=name,Values=amazon-linux-2023*" \
              "Name=architecture,Values=x86_64" \
              "Name=state,Values=available" \
    --owners "amazon" \
    --query "Images | sort_by(@, &CreationDate) | [-1].ImageId" \
    --output text)

if [ -z "$image_id" ] || [ "$image_id" == "None" ]; then
    echo ">[ERRO] Nenhuma AMI do Amazon Linux 2023 encontrada."
    exit 1
else
    echo "> AMI encontrada: $image_id"
fi

# Obter o ID do Security Group bia-dev
security_group_id=$(aws ec2 describe-security-groups --group-names "bia-dev" --query "SecurityGroups[0].GroupId" --output text 2>/dev/null)

if [ -z "$security_group_id" ]; then
    echo ">[ERRO] Security group bia-dev não foi criado na VPC $vpc_id"
    exit 1
else
    echo "> Security Group encontrado: $security_group_id"
fi

# Criar a instância EC2
aws ec2 run-instances --image-id $image_id --count 1 --instance-type t3.micro \
--security-group-ids $security_group_id --subnet-id $subnet_id --associate-public-ip-address \
--block-device-mappings '[{"DeviceName":"/dev/xvda","Ebs":{"VolumeSize":15,"VolumeType":"gp2"}}]' \
--tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=bia-dev-b}]' \
--iam-instance-profile Name=role-acesso-ssm --user-data file://user_data_ec2_zona.sh

if [ $? -eq 0 ]; then
    echo "> Instância EC2 criada com sucesso na Subnet $subnet_id (Zona us-east-1b) usando a AMI $image_id"
else
    echo ">[ERRO] Falha na criação da instância EC2."
fi
