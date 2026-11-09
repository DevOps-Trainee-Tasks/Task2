locals {
    aws_region = "us-east-1"
    project = "task2"
    smtp_password_parameter_arn = "arn:aws:ssm:${local.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${local.project}/grafana/smtp-password"
    bastion_ami_id = "ami-0043f27122a2eb596"
    bastion_instance_type = "m7i-flex.large"
    bastion_key_name  = "task1-key"
    llm_ami_id = "ami-0ade00ea1fbf7e9f7"
    llm_instance_type = "m7i-flex.large"
    rds_instance_class = "db.t4g.micro"
    rds_db_name = "manualdb"
    rds_db_username = "dbadmin"
    rds_engine_version = "16"
    rds_allocated_storage = 20
}