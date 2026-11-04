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

resource "aws_iam_role_policy" "cloudwatch_read" {
  name = "${var.name_prefix}-monitoring-cloudwatch-read"
  role = aws_iam_role.monitoring.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:ListMetrics",
          "cloudwatch:GetMetricData",
          "ec2:DescribeInstances",
          "ec2:DescribeTags",
          "ec2:DescribeRegions",
          "tag:GetResources",
          "logs:DescribeLogGroups"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish",
          "sns:GetTopicAttributes"
        ]
        Resource = var.sns_topic_arn
      }
    ]
  })
}

resource "aws_iam_instance_profile" "monitoring" {
  name = "${var.name_prefix}-monitoring-profile"
  role = aws_iam_role.monitoring.name
}