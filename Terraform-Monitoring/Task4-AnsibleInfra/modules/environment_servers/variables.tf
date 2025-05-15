# Имя контура ( "dev", "staging", "prod" )
variable "env_name" {
  description = "Name of the environment"
  type        = string
}

# Префикс подсети для контура
variable "subnet_prefix" {
  description = "Subnet prefix for the environment network (e.g., 172.20.0)"
  type        = string
}

# Кол-во серверов для создания в этом контуре
variable "server_count" {
  description = "Number of server containers to create in this environment"
  type        = number
}

# Имя пользователя для SSH доступа
variable "ssh_user" {
  description = "Username for SSH access"
  type        = string
}

# Пароль для SSH доступа
variable "ssh_password" {
  description = "Password for SSH access"
  type        = string
  sensitive   = true # Чувствительные данные
}
