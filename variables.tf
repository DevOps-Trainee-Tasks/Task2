variable "my_ip" {
  type = string
}

variable "alert_email" {
  type = string
}

variable "webui_db_username" {
  type = string
}

variable "webui_db_password" {
  type      = string
  sensitive = true
}

variable "webui_secret_key" {
  type      = string
  sensitive = true
}