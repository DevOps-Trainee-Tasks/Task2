# Task 2 — AWS Monitoring and Alerting

This project extends the Task 1 AWS infrastructure with monitoring and a browser interface for Ollama. Terraform provisions the network, compute, load balancer, PostgreSQL database, security groups, and credentials. Packer builds the Amazon Machine Images (AMIs) used by the Bastion and LLM instances.

## Architecture

| Component | Location | Purpose |
| --- | --- | --- |
| Bastion EC2 | Public subnet | Runs Prometheus, Grafana, and Open WebUI; provides SSH access. |
| Ollama EC2 instances | Private server subnets | Run Ollama and Node Exporter; managed by an Auto Scaling Group (ASG). |
| Application Load Balancer | Public subnets | Forwards HTTP traffic on port `11434` to Ollama and checks `/api/tags`. |
| PostgreSQL RDS | Private database subnets | Stores Open WebUI data. |
| NAT gateway | Public subnet | Provides outbound internet access to private subnets. |

Prometheus runs on the Bastion and discovers running LLM instances by their EC2 `Name=ollama` tag. It collects Node Exporter metrics on port `9100`. Grafana uses Prometheus and CloudWatch as data sources and includes dashboards and alert configuration from the Packer-built Bastion AMI. Open WebUI runs as a Docker container on the Bastion and connects to Ollama through the ALB and to PostgreSQL through RDS.

The ASG starts two LLM instances and can scale between two and four based on average CPU utilization.

## Repository structure

```text
Task2/
├── backend.tf                 # S3 backend and state locking
├── locals.tf                  # AWS region, AMI IDs, instance sizes, database settings
├── main.tf                    # Provider and module calls
├── variables.tf               # Terraform input variables
├── terraform_tfvars_example.txt
├── modules/
│   ├── vpc/                   # VPC, subnets, routing, internet and NAT gateways
│   ├── sg/                    # Security groups and ingress/egress rules
│   ├── ec2/                   # Bastion EC2 and its IAM instance profile
│   ├── asg/                   # Ollama launch template, ASG, scaling policy
│   ├── alb/                   # Ollama load balancer, target group, listener
│   ├── rds/                   # PostgreSQL instance and DB subnet group
│   ├── webui/                 # Bastion access to the Ollama ALB
│   └── webui-creds/           # Open WebUI credentials in Secrets Manager
└── scripts/
    └── open-webui.sh          # Bastion startup script for Open WebUI and RDS access
```

The sibling `../packer_task2/` project owns the software and configuration baked into the AMIs:

- `bastion/`: Prometheus, Grafana, data sources, dashboards, alert rules, and SMTP configuration.
- `llm/`: Ollama, the configured model, and Node Exporter.

This Terraform repository keeps only `scripts/open-webui.sh`, which runs when the Bastion starts. Grafana dashboards and the other installation scripts belong to the Packer project.

## Prerequisites

- Terraform and AWS credentials with access to the resources in this project.
- Packer, if the Bastion or LLM AMIs need to be built or rebuilt.
- An S3 bucket for the Terraform backend. Check `backend.tf` before `terraform init`: its current bucket and `manual-task1/terraform.tfstate` key must point to the intended state for this deployment.
- An EC2 key pair matching `bastion_key_name` in `locals.tf` (`task1-key` in the current configuration).
- An SSM Parameter Store parameter named `/task2/grafana/smtp-password` for Grafana's SMTP password. The name follows the `project` value in `locals.tf`.

The configuration currently uses AWS region `us-east-1` and Availability Zones `us-east-1a` and `us-east-1b`.

## 1. Build or select the AMIs

If the AMI IDs in `locals.tf` already refer to your completed Packer images in the chosen region, use those IDs. To build fresh images, run these commands from the sibling Packer project:

```bash
cd ../packer_task2/bastion
packer init .
packer build -var 'alert_email=you@example.com' .

cd ../llm
packer init .
packer build .
```

Copy the AMI IDs reported by Packer into `bastion_ami_id` and `llm_ami_id` in `Task2/locals.tf`. The Grafana email address is passed to the **Bastion Packer build** through `alert_email`. The `alert_email` variable in this Terraform repository is currently declared but is not used by Terraform resources.

## 2. Set Terraform inputs

From the `Task2/` directory, copy the example and edit its values:

```bash
cp terraform_tfvars_example.txt terraform.tfvars
```

| Variable | Meaning |
| --- | --- |
| `my_ip` | Your public IP in CIDR form, such as `203.0.113.10/32`. Controls inbound access to the Bastion and ALB. |
| `webui_db_username` | Database role created for Open WebUI at Bastion startup. |
| `webui_db_password` | Password for that database role. |
| `webui_secret_key` | Open WebUI session secret. |
| `alert_email` | Currently unused by Terraform; set the email during the Bastion Packer build. |

Set your own values for the IP and credentials. Do not commit `terraform.tfvars`: its credentials are supplied to Secrets Manager through Terraform and are also part of Terraform state.

## 3. Deploy

Check the backend settings and AMI IDs, then run:

```bash
terraform init
terraform plan
terraform apply
```

Review the plan before approving the apply. There are no root Terraform outputs for the Bastion IP or ALB DNS name, so find them in the AWS EC2 console after deployment.

At first boot, the Bastion's `open-webui.sh` installs Docker and PostgreSQL client tools, reads the Open WebUI and RDS master credentials from Secrets Manager, creates or updates the Open WebUI database role, and starts the Open WebUI container. The Bastion IAM role grants access to those secrets, CloudWatch metrics, EC2 discovery, and the SMTP parameter.

## Access and checks

From the public IP specified by `my_ip`, open:

| Service | Address |
| --- | --- |
| Open WebUI | `http://<bastion-public-ip>/` |
| Grafana | `http://<bastion-public-ip>:3000/` |
| Prometheus | `http://<bastion-public-ip>:9090/` |
| Ollama API | `http://<alb-dns-name>:11434/api/tags` |

In the AWS console, confirm that the ASG instances are running and the ALB targets are healthy. In Prometheus, check that the `prometheus` and `llm-node` targets are up; the LLM targets are discovered by EC2 tags. In Grafana, inspect the configured Prometheus and CloudWatch data sources and dashboards.

To remove the Terraform-managed infrastructure after the exercise, run `terraform destroy` from `Task2/` using the same backend and variable values. Packer-built AMIs and the pre-existing S3 backend are separate from this Terraform deployment.
