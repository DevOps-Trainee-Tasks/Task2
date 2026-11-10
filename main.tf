terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
provider "aws" {
  region = local.aws_region
}

data "aws_caller_identity" "current" {}

module "vpc" {
  source = "./modules/vpc"
  nat_gateway_public_subnet_index = 0
  name_prefix = local.project

cidr = "10.0.0.0/24"

  available_zones_list = [
    "us-east-1a",
    "us-east-1b"
  ]
  public_subnets = [
    "10.0.0.0/27",
    "10.0.0.32/27"
  ]
  private_servers_subnets = [
    "10.0.0.64/27",
    "10.0.0.96/27"
  ]
  private_db_subnets = [
    "10.0.0.128/27",
    "10.0.0.160/27"
  ]
}

module "sg" {
  source = "./modules/sg"
  main_vpc_id = module.vpc.vpc_id

  security_groups = {
    bastion_sg = {
      ingress_ports_tcp = [22, 80, 3000, 9090]
      allowed_cidr_blocks = [var.my_ip]
      allowed_security_groups = []
    }

    alb_sg = {
      ingress_ports_tcp = [11434]
      allowed_cidr_blocks = [var.my_ip]
      allowed_security_groups = []
    }

    llm_bastion_sg = {
      ingress_ports_tcp = [22, 9100]
      allowed_cidr_blocks = []
      allowed_security_groups = ["bastion_sg"]
    }

    llm_alb_sg = {
      ingress_ports_tcp = [11434]
      allowed_cidr_blocks = []
      allowed_security_groups = ["alb_sg"]
    }

    rds_sg = {
      ingress_ports_tcp = [5432]
      allowed_cidr_blocks = []
      allowed_security_groups = ["llm_alb_sg", "bastion_sg"]
    }

  }
}

module "bastion" {
  source = "./modules/ec2"

  ec2_name = "Bastion"
  name_prefix = local.project
  ami_id = local.bastion_ami_id
  instance_type = local.bastion_instance_type
  subnet_id = module.vpc.public_subnet_ids[0]
  security_group_ids = [module.sg.security_group_ids["bastion_sg"]]
  key_name = local.bastion_key_name
  smtp_password_parameter_arn = local.smtp_password_parameter_arn
  user_data = templatefile("${path.root}/scripts/open-webui.sh", {
  ollama_url = "http://${module.alb.alb_dns}:11434"
  db_host = module.rds.address
  db_name = local.rds_db_name
  webui_secret_arn = module.webui_credentials.arn
  rds_master_secret_arn = module.rds.master_secret_arn
  })
  webui_secret_arn = module.webui_credentials.arn
  rds_master_secret_arn = module.rds.master_secret_arn
}

module "alb" {
    source = "./modules/alb"

    name_prefix = local.project
    vpc_id = module.vpc.vpc_id
    public_subnet_ids = module.vpc.public_subnet_ids
    security_groups_id = module.sg.security_group_ids["alb_sg"]
    ollama_port = 11434
}

module "asg" {
  source = "./modules/asg"

  name_prefix = local.project
  ami_id = local.llm_ami_id
  instance_type = local.llm_instance_type
  key_name = local.bastion_key_name
  security_group_ids = [
    module.sg.security_group_ids["llm_bastion_sg"],
    module.sg.security_group_ids["llm_alb_sg"]
  ]
  private_subnet_ids = module.vpc.private_servers_subnet_ids
  target_group_arn = module.alb.target_group_arn
}

module "rds" {
    source = "./modules/rds"

    name_prefix = local.project
    private_db_subnet_ids = module.vpc.private_db_subnet_ids
    rds_security_group_id = module.sg.security_group_ids["rds_sg"]
    instance_class = local.rds_instance_class
    db_name = local.rds_db_name
    db_username = local.rds_db_username
    engine_version = local.rds_engine_version
    allocated_storage = local.rds_allocated_storage
}

module "webui" {
  source = "./modules/webui"

  alb_security_group_id = module.sg.security_group_ids["alb_sg"]
  bastion_public_ip = module.bastion.public_ip
}

module "webui_credentials" {
  source = "./modules/webui-creds"

  name_prefix = local.project
  db_username = var.webui_db_username
  db_password = var.webui_db_password
  webui_secret_key = var.webui_secret_key
}