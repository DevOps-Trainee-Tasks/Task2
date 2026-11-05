variable "main_vpc_id" {
  type = string
}

variable "security_groups" {
  type = map(object({
    ingress_ports_tcp = list(number)
    allowed_cidr_blocks = list(string)
    allowed_security_groups = list(string)
  }))
}
