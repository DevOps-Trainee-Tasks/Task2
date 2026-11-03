variable "main_vpc_id" {
  type = string
}

variable "security_groups" {
  type = map(object({
    ingress_rules = map(object({
      ports        = list(number)
      protocol     = optional(string, "tcp")
      cidr_ipv4    = optional(string)
      source_group = optional(string)
    }))
  }))
}
