variable "ami_id" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "security_group_ids" {
  type = list(string)
}

variable "key_name" {
  type = string
}

variable "user_data" {
  type = string
}

variable "name_prefix" {
  type = string
}

variable "ec2_name" {
  type = string
}

variable "smtp_password_parameter_arn" {
  type = string
}