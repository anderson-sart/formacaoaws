data "aws_iam_policy_document" "ecs_instance_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}


resource "aws_iam_role" "ecs_instance_role" {
  name_prefix        = "ecs-instace-role-tf"
  assume_role_policy = data.aws_iam_policy_document.ecs_instance_role.json
}

resource "aws_iam_role_policy_attachment" "ecs_instance_role_policy" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_policy" "secrets_manager_policy" {
  name        = "ecs-instance-secrets-manager-policy"
  description = "Permite acessar o segredo do RDS no AWS Secrets Manager"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue"
        ],
        Effect   = "Allow",
        Resource = "${tolist(aws_db_instance.bia.master_user_secret)[0].secret_arn}"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_policy_2" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = aws_iam_policy.secrets_manager_policy.arn
}

resource "aws_iam_instance_profile" "ecs_node" {
  name_prefix = "ecs-instance-role-tf-profile"
  path        = "/ecs/instance/"
  role        = aws_iam_role.ecs_instance_role.name
}

