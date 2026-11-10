resource "aws_iam_role" "monitoring" {
  name = "${var.name_prefix}-monitoring-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "monitoring" {
  name = "${var.name_prefix}-monitoring-policy"
  role = aws_iam_role.monitoring.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:ListMetrics",
          "cloudwatch:GetMetricData",
          "logs:DescribeLogGroups",
          "ec2:DescribeInstances",
          "ec2:DescribeTags",
          "ec2:DescribeRegions"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = "ssm:GetParameter"
        Resource = var.smtp_password_parameter_arn
      },
      {
        Effect   = "Allow"
        Action   = "secretsmanager:GetSecretValue"
        Resource = [var.webui_secret_arn, var.rds_master_secret_arn]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "monitoring" {
  name = "${var.name_prefix}-monitoring-profile"
  role = aws_iam_role.monitoring.name
}

resource "aws_instance" "ec2" {
    ami = var.ami_id
    instance_type = var.instance_type
    subnet_id = var.subnet_id
    vpc_security_group_ids = var.security_group_ids
    key_name = var.key_name
    user_data_base64 = base64gzip(var.user_data)
    tags = {
        Name = "${var.ec2_name}"
    }
    iam_instance_profile = aws_iam_instance_profile.monitoring.name
}