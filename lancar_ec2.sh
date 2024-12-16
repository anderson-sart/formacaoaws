# Obter o ID da VPC padrão
vpc_id=$(aws ec2 describe-vpcs --filters Name=isDefault,Values=true --query "Vpcs[0].VpcId" --output text)

# Alterar para selecionar a subnet na zona us-east-1b
subnet_id=$(aws ec2 describe-subnets --filters Name=vpc-id,Values=$vpc_id Name=availabilityZone,Values=us-east-1b --query "Subnets[0].SubnetId" --output text)

# Obter o ID do security group bia-dev
security_group_id=$(aws ec2 describe-security-groups --group-names "bia-dev" --query "SecurityGroups[0].GroupId" --output text 2>/dev/null)

# Verificar se o security group existe
if [ -z "$security_group_id" ]; then
    echo ">[ERRO] Security group bia-dev não foi criado na VPC $vpc_id"
    exit 1
fi

# Criar instância EC2 na zona us-east-1b
aws ec2 run-instances --image-id ami-02f3f602d23f1659d --count 1 --instance-type t3.micro \
--security-group-ids $security_group_id --subnet-id $subnet_id --associate-public-ip-address \
--block-device-mappings '[{"DeviceName":"/dev/xvda","Ebs":{"VolumeSize":15,"VolumeType":"gp2"}}]' \
--tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=bia-dev-b}]' \
--iam-instance-profile Name=role-acesso-ssm --user-data file://user_data_ec2_zona.sh
