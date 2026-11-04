variable "name_prefix" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "alb_arn" {
  type = string
}

variable "alb_security_group_id" {
  type = string
}

variable "bastion_instance_id" {
  type = string
}

variable "bastion_public_ip" {
  type = string
}