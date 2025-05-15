# Входные переменные (Input Variables) для модуля Environment
# Эти переменные получают значения из корневого модуля (main.tf),
# где вызывается этот модуль.

variable "env_name" {
  description = "Name of the environment (e.g., dev, staging, prod, test)"
  type        = string
}

variable "web_port" {
  description = "External port for web server in this environment"
  type        = number
}

variable "db_user" {
  description = "PostgreSQL user for this environment"
  type        = string
}

variable "db_password" {
  description = "PostgreSQL password for this environment"
  type        = string
}

variable "db_name" {
  description = "PostgreSQL database name for this environment"
  type        = string
}
